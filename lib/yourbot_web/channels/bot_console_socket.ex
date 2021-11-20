defmodule YourBotWeb.BotConsoleSocket do
  @moduledoc """
  Handles communication with a single bot
  """

  import Phoenix.Socket
  alias YourBot.Bots.Bot
  alias YourBot.Bots
  alias YourBot.Accounts.APIToken

  defmodule RPC do
    defstruct id: nil, kind: nil, action: nil, args: %{}

    def decode(rpc)

    def decode(rpc) when is_binary(rpc) do
      with {:ok, rpc} <- Jason.decode(rpc) do
        decode(rpc)
      else
        _ ->
          {:ok, error} =
            encode(%__MODULE__{
              id: System.unique_integer([:positive]),
              kind: "error",
              action: "decode",
              args: %{message: "could not decode json"}
            })

          {:error, error}
      end
    end

    def decode(%{"id" => id, "kind" => kind, "action" => action, "args" => args}) do
      {:ok, %__MODULE__{id: id, kind: kind, action: action, args: args}}
    end

    def decode(_) do
      {:ok, error} =
        encode(%__MODULE__{
          id: System.unique_integer([:positive]),
          kind: "error",
          action: "decode",
          args: %{message: "could not decode rpc"}
        })

      {:error, error}
    end

    def encode(%__MODULE__{id: id, kind: kind, action: action, args: %{} = args}) do
      Jason.encode(%{id: id, kind: kind, action: action, args: args})
    end
  end

  @behaviour :cowboy_websocket

  # entry point of the websocket socket.
  # WARNING: this is where you would need to do any authentication
  #          and authorization. Since this handler is invoked BEFORE
  #          our Phoenix router, it will NOT follow your pipelines defined there.
  #
  # WARNING: this function is NOT called in the same process context as the rest of the functions
  #          defined in this module. This is notably dissimilar to other gen_* behaviours.
  @impl :cowboy_websocket
  def init(req, opts) do
    with %{"bot_id" => bot_id, "authorization" => token} <- URI.decode_query(req.qs),
         {:ok, user} <- APIToken.verify(token, "user"),
         %Bot{} = bot <- Bots.get_bot(user, bot_id),
         socket <- into_socket(req, opts) do
      {:cowboy_websocket, req,
       socket
       |> assign(:bot, bot)}
    else
      _ ->
        {:reply, {:close, 1000, "not authorized"}, opts}
    end
  end

  # as long as `init/2` returned `{:cowboy_websocket, req, opts}`
  # this function will be called. You can begin sending packets at this point.
  # We'll look at how to do that in the `websocket_handle` function however.
  # This function is where you might want to  implement `Phoenix.Presence`, schedule an `after_join` message etc.
  @impl :cowboy_websocket
  def websocket_init(socket) do
    socket.endpoint.subscribe("bots")
    socket.endpoint.subscribe("crud:bots")
    bot = sync_bot(socket.assigns.bot, nil)

    tty_data =
      if bot.uptime_status == "up" do
        for data <- YourBot.BotSandbox.get_stdout(bot) do
          {:ok, rpc} = tty_data_rpc(bot, data)
          {:text, rpc}
        end
      end

    {:ok, rpc} = status_rpc(bot)
    Process.send_after(self(), :send_ping, 5000)
    {[{:text, rpc} | tty_data || []], assign(socket, :bot, bot)}
  end

  @impl :cowboy_websocket
  def websocket_handle(frame, socket)

  # :ping is not handled for us like in Phoenix Channels.
  # We must explicitly send :pong messages back.
  def websocket_handle(:ping, socket), do: {[:pong], socket}

  def websocket_handle(:pong, socket) do
    Process.send_after(self(), :send_ping, 5000)
    {[], socket}
  end

  # a message was delivered from a client. Here we handle it by just echoing it back
  # to the client.
  def websocket_handle({:text, message}, socket) do
    case RPC.decode(message) do
      {:ok, rpc} ->
        handle_rpc(rpc, socket)

      {:error, _} ->
        {[{:text, Jason.encode!(%{errors: ["could not decode json"]})}], socket}
    end
  end

  # This function is where we will process all *other* messages that get delivered to the
  # process mailbox. This function isn't used in this handler.
  @impl :cowboy_websocket
  def websocket_info(info, socket)

  def websocket_info(:send_ping, socket) do
    {[:ping], socket}
  end

  def websocket_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: presence}, socket) do
    bot = sync_bot(socket.assigns.bot, presence)
    {:ok, rpc} = status_rpc(bot)
    {[{:text, rpc}], assign(socket, :bot, bot)}
  end

  def websocket_info(
        %Phoenix.Socket.Broadcast{event: "tty_data", payload: %{bot: %{id: id}, data: data}},
        %{assigns: %{bot: %{id: id}}} = socket
      ) do
    {:ok, rpc} = tty_data_rpc(socket.assigns.bot, data)
    {[{:text, rpc}], socket}
  end

  def websocket_info(
        %Phoenix.Socket.Broadcast{event: "update", payload: %{new: %{id: id} = bot}},
        %{assigns: %{bot: %{id: id}}} = socket
      ) do
    bot = sync_bot(bot, nil)
    {:ok, rpc} = status_rpc(bot)
    {[{:text, rpc}], assign(socket, :bot, bot)}
  end

  def websocket_info(_info, socket), do: {[], socket}

  def handle_rpc(%RPC{kind: "sandbox", action: "stop"} = rpc, socket) do
    with :ok <- YourBot.BotSupervisor.terminate_child(socket.assigns.bot),
         {:ok, rpc} <- RPC.encode(rpc) do
      {[{:text, rpc}], socket}
    else
      _ ->
        rpc = %RPC{
          kind: "error",
          action: "terminate_child",
          args: %{message: "failed to stop sandbox"}
        }

        {:ok, error} = RPC.encode(rpc)
        {[{:text, error}], socket}
    end
  end

  def handle_rpc(%RPC{kind: "sandbox", action: "start"} = rpc, socket) do
    with {:ok, _pid} <- YourBot.BotSupervisor.start_child(socket.assigns.bot),
         {:ok, rpc} <- RPC.encode(rpc) do
      {[{:text, rpc}], socket}
    else
      _ ->
        rpc = %RPC{
          kind: "error",
          action: "start_child",
          args: %{message: "failed to start sandbox"}
        }

        {:ok, error} = RPC.encode(rpc)
        {[{:text, error}], socket}
    end
  end

  def handle_rpc(%RPC{kind: "sandbox", action: "status"} = rpc, socket) do
    bot = sync_bot(socket.assigns.bot, nil)
    {:ok, rpc} = status_rpc(bot, rpc)
    {[{:text, rpc}], assign(socket, :bot, bot)}
  end

  def handle_rpc(command, socket) do
    {:ok, reply} =
      RPC.encode(%RPC{
        id: command.id,
        kind: "error",
        action: "handle_rpc",
        args: %{message: "unknown command"}
      })

    {[{:text, reply}], socket}
  end

  defp status_rpc(bot, rpc \\ %RPC{}) do
    rpc = %RPC{
      rpc
      | kind: "sandbox",
        action: "status",
        args: %{
          uptime_status: bot.uptime_status,
          deploy_status: bot.deploy_status
        }
    }

    RPC.encode(rpc)
  end

  defp tty_data_rpc(_bot, data) do
    rpc = %RPC{
      kind: "sandbox",
      action: "tty_data",
      args: %{
        message: data
      }
    }

    RPC.encode(rpc)
  end

  def into_socket(req, _opts) do
    %Phoenix.Socket{
      endpoint: YourBotWeb.Endpoint,
      private: %{req: req}
    }
  end

  defp sync_bot(%YourBot.Bots.Bot{id: id} = bot, nil) do
    presence = YourBot.Bots.Presence.find(bot)

    if presence do
      sync_bot(bot, %{joins: %{"#{id}" => presence}})
    else
      sync_bot(bot, %{leaves: %{"#{id}" => bot}})
    end
  end

  defp sync_bot(%YourBot.Bots.Bot{id: id} = bot, payload) when is_map(payload) do
    id = to_string(id)
    joins = Map.get(payload, :joins, %{})
    leaves = Map.get(payload, :leaves, %{})

    cond do
      meta = joins[id] ->
        updates = YourBot.Bots.Presence.into_meta(meta)
        Map.merge(bot, updates)

      leaves[id] ->
        %{bot | uptime_status: "down"}

      true ->
        bot
    end
  end
end
