defmodule YourBot.BotSandbox do
  use GenServer
  import YourBot.BotNameProvider, only: [via: 2]
  alias YourBot.Bots.Bot
  alias YourBot.Bots.Project
  alias YourBot.Bots.Presence
  require Logger

  @endpoint YourBotWeb.Endpoint

  def start_link(%Bot{} = bot) do
    GenServer.start_link(__MODULE__, bot, name: via(bot, __MODULE__))
  end

  defp handshake(bot, pid) do
    GenServer.cast({__MODULE__, :"#{bot.id}@#{node_name()}"}, {:handshake, pid})
  end

  def get_stdout(bot) do
    GenServer.call(via(bot, __MODULE__), :get_stdout)
  end

  @impl GenServer
  def init(bot) do
    Logger.metadata(bot_id: bot.id)
    # @endpoint.subscribe("crud:bots")
    python = System.find_executable("python3")
    sandbox_py = Application.app_dir(:yourbot, ["priv", "sandbox", "sandbox.py"])
    {:ok, _presence} = Presence.track(self(), "bots", "#{bot.id}", default_presence())
    project = Project.load_project(bot.project)

    sandbox_dir =
      Path.join([sandbox_dir(), "#{bot.id}"])
      |> Path.expand()

    args =
      [
        sandbox_py,
        "--name",
        "#{bot.id}@#{node_name()}",
        "--cookie",
        to_string(Node.get_cookie()),
        "--sandbox",
        sandbox_dir,
        "--database",
        database_url(bot)
      ] ++ chroot()

    env =
      Enum.map(:os.env(), fn {key, _} -> {to_string(key), nil} end) ++
        Enum.map(project.environment_variables, fn %{key: key, value: value} ->
          {to_string(key), to_string(value)}
        end) ++
        [
          {"DATABASE_URL", database_url(bot)}
        ]

    {:ok, tty} =
      ExTTY.start_link(
        handler: self(),
        type: :muontrap,
        shell_opts: [
          [
            exec: python,
            args: args,
            env: env
          ]
        ]
      )

    {:ok, %{bot: bot, tty: tty, stdout: []}, {:continue, :connect}}
  end

  @impl GenServer
  def terminate(_reason, state) do
    {:ok, _} =
      Presence.update(self(), "bots", "#{state.bot.id}", fn meta ->
        %{meta | uptime_status: "down"}
      end)
  end

  @impl GenServer
  def handle_continue(:connect, state) do
    case Node.connect(:"#{state.bot.id}@#{node_name()}") do
      true ->
        Logger.info("Connected to #{state.bot.id}@#{node_name()}")
        Node.monitor(:"#{state.bot.id}@#{node_name()}", true)
        {:noreply, state, {:continue, :handshake}}

      false ->
        Logger.warn("Failed to connect to #{state.bot.id}@#{node_name()}")

        {:ok, _} =
          Presence.update(self(), "bots", "#{state.bot.id}", fn meta ->
            %{meta | uptime_status: "boot"}
          end)

        Process.sleep(1000)
        {:noreply, state, {:continue, :connect}}
    end
  end

  def handle_continue(:handshake, state) do
    handshake(state.bot, self())
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_stdout, _from, state) do
    {:reply, state.stdout, state}
  end

  @impl GenServer
  def handle_info({:tty_data, data}, state) do
    Logger.debug(%{tty_data: data, bot: state.bot.id})
    @endpoint.broadcast!("bots", "tty_data", %{bot: state.bot, data: data})
    {:noreply, %{state | stdout: state.stdout ++ [data]}}
  end

  def handle_info({:nodedown, _node}, state) do
    {:ok, _} =
      Presence.update(self(), "bots", "#{state.bot.id}", fn meta ->
        %{meta | uptime_status: "down"}
      end)

    {:stop, :nodedown, state}
  end

  def handle_info({:stacktrace, reason, st}, state) do
    stacktrace =
      Enum.map(st, fn {name, filename, lineno} ->
        {__MODULE__, String.to_atom(name), 0, file: to_charlist(filename), line: lineno}
      end)

    exception = Exception.format(:exit, reason, stacktrace)
    Logger.error("Caught python exception in sandbox: " <> exception)
    {:stop, reason, state}
  end

  def handle_info({:exec, result}, state) do
    Logger.info("Sandbox up and running: #{inspect(result)}")

    {:ok, _} =
      Presence.update(self(), "bots", "#{state.bot.id}", fn meta ->
        %{meta | uptime_status: "up"}
      end)

    {:noreply, state}
  end

  def node_name, do: Application.get_env(:yourbot, __MODULE__)[:node_name]

  def chroot do
    chroot = Application.get_env(:yourbot, __MODULE__)[:chroot]
    if chroot, do: ["--chroot", chroot], else: []
  end

  def database_url(bot) do
    chroot = Application.get_env(:yourbot, __MODULE__)[:chroot]

    if chroot,
      do: Path.join(["/", "db", "#{bot.project.uuid}.sqlite3"]),
      else: YourBot.Bots.Project.Container.path(bot.project)
  end

  def sandbox_dir() do
    chroot = Application.get_env(:yourbot, __MODULE__)[:chroot]

    if chroot,
      do: Path.join(["/", "sandbox"]),
      else: Application.get_env(:yourbot, __MODULE__)[:sandbox_dir]
  end

  def default_presence do
    %{
      uptime_status: "boot"
    }
  end
end
