defmodule YourBot.BotSandbox do
  use GenServer
  import YourBot.BotNameProvider, only: [via: 2]
  alias YourBot.Bots.Bot
  require Logger

  @endpoint YourBotWeb.Endpoint

  def start_link(%Bot{} = bot) do
    GenServer.start_link(__MODULE__, bot, name: via(bot, __MODULE__))
  end

  def exec_code(bot) do
    GenServer.cast({__MODULE__, :"#{bot.id}@#{node_name()}"}, {:code, bot.code})
  end

  @impl GenServer
  def init(bot) do
    # @endpoint.subscribe("crud:bots")
    python = System.find_executable("python3")
    sandbox_py = Application.app_dir(:yourbot, ["priv", "sandbox", "sandbox.py"])

    args = [
      sandbox_py,
      "--name",
      "#{bot.id}@#{node_name()}",
      "--cookie",
      to_string(Node.get_cookie())
    ]

    {:ok, tty} =
      ExTTY.start_link(
        handler: self(),
        type: :muontrap,
        shell_opts: [
          [
            exec: python,
            args: args
          ]
        ]
      )

    {:ok, %{bot: bot, tty: tty}, {:continue, :connect}}
  end

  @impl GenServer
  def handle_continue(:connect, state) do
    case Node.connect(:"#{state.bot.id}@#{node_name()}") do
      true ->
        Logger.info("Connected to #{state.bot.id}@#{node_name()}")
        Node.monitor(:"#{state.bot.id}@#{node_name()}", true)
        {:noreply, state}

      false ->
        Logger.warn("Failed to connect to #{state.bot.id}@#{node_name()}")
        Process.sleep(1000)
        {:noreply, state, {:continue, :connect}}
    end
  end

  @impl GenServer
  def handle_info({:tty_data, data}, state) do
    @endpoint.broadcast!("sandbox", "tty_data", %{bot: state.bot, data: data})
    {:noreply, state}
  end

  def node_name, do: Application.get_env(:yourbot, __MODULE__)[:node_name]
end
