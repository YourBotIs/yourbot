defmodule YourBotWeb.BotLive do
  use Surface.LiveView

  alias YourBot.Accounts
  alias MonacoEditor
  alias YourBot.Bots
  alias YourBot.Bots.Bot

  alias SurfaceBulma.Button
  alias YourBotWeb.Components.BotModal
  require Logger

  data show_bot_dialog, :boolean, default: false

  def mount(_, %{"user_token" => token}, socket) do
    user = Accounts.get_user_by_session_token(token)

    bots =
      Bots.list_bots(user)
      |> Enum.map(fn bot -> sync_bot(bot, nil) end)

    bot_changeset = Bots.change_bot(%Bot{})
    socket.endpoint.subscribe("crud:bots")
    socket.endpoint.subscribe("bots")

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:bots, bots)
     |> assign(:bot_changeset, bot_changeset)
     |> assign(:action, :create)}
  end

  def handle_event("show_bot_dialog", _, socket) do
    bot_changeset = Bots.change_bot(socket.assigns.bot_changeset.data)

    {:noreply,
     socket
     |> assign(:show_bot_dialog, true)
     |> assign(:bot_changeset, bot_changeset)}
  end

  def handle_event("hide_dialog", _, socket) do
    bots = Bots.list_bots(socket.assigns.user)

    {:noreply,
     socket
     |> assign(:bots, bots)
     |> assign(:show_bot_dialog, false)}
  end

  def handle_event("change", %{"bot" => params}, socket) do
    case socket.assigns.action do
      :create ->
        changeset = Bots.change_bot(socket.assigns.bot_changeset.data, params)

        {:noreply,
         socket
         |> assign(:bot_changeset, changeset)}
    end
  end

  def handle_event("save", %{"bot" => params}, socket) do
    case socket.assigns.action do
      :create ->
        create_bot(params, socket)
    end
  end

  def handle_event("select_bot", %{"bot_id" => bot_id}, socket) do
    bot_changeset =
      Bots.get_bot(bot_id)
      |> sync_bot(nil)
      |> Bots.change_bot()

    socket =
      if YourBot.BotSupervisor.lookup_child(bot_changeset.data) do
        tty_data = YourBot.BotSandbox.get_stdout(bot_changeset.data) |> Enum.join()
        push_event(socket, "sandbox", %{"tty_data" => tty_data})
      else
        socket
      end

    {:noreply,
     socket
     |> assign(:bot_changeset, bot_changeset)
     |> assign(:action, :edit)
     |> push_event(:monaco_load, %{value: bot_changeset.data.code})}
  end

  def handle_event("monaco_change", %{"value" => code}, socket) do
    changeset = Bots.change_bot(socket.assigns.bot_changeset.data, %{code: code})

    {:noreply,
     socket
     |> assign(:bot_changeset, changeset)}
  end

  def handle_event("save_code", %{}, socket) do
    if Ecto.Changeset.get_change(socket.assigns.bot_changeset, :code) do
      bot_changeset =
        Bots.sync_code!(
          socket.assigns.bot_changeset.data,
          socket.assigns.bot_changeset.changes.code
        )
        |> Bots.change_bot()

      {:noreply,
       socket
       |> assign(:bot_changeset, bot_changeset)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("restart_code", %{"bot" => bot_id}, socket) do
    bot_changeset = Bots.get_bot(bot_id) |> sync_bot(nil) |> Bots.change_bot()

    if pid =
         GenServer.whereis(YourBot.BotNameProvider.via(bot_changeset.data, YourBot.BotSandbox)) do
      DynamicSupervisor.terminate_child(YourBot.BotSupervisor, pid)
    end

    case YourBot.BotSupervisor.start_child(bot_changeset.data) do
      {:ok, _pid} ->
        {:noreply,
         socket
         |> put_flash(:info, "Started")
         |> assign(:bot_changeset, bot_changeset)}
    end
  end

  def handle_event("stop_code", %{"bot" => bot_id}, socket) do
    YourBot.Bots.get_bot(bot_id)
    |> YourBot.BotSupervisor.terminate_child()

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{topic: "crud:bots"}, socket) do
    bots =
      Bots.list_bots(socket.assigns.user)
      |> Enum.map(fn bot -> sync_bot(bot, nil) end)

    {:noreply,
     socket
     |> assign(:bots, bots)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "bots",
          event: "tty_data",
          payload: %{bot: bot, data: tty_data}
        },
        socket
      ) do
    if bot.id == socket.assigns.bot_changeset.data.id do
      {:noreply,
       socket
       |> push_event("sandbox", %{"tty_data" => tty_data})}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "bots",
          event: "presence_diff",
          payload: presence
        },
        socket
      ) do
    bots =
      Enum.map(socket.assigns.bots, fn bot ->
        sync_bot(bot, presence)
      end)

    bot_changeset = sync_bot(socket.assigns.bot_changeset.data, presence) |> Bots.change_bot()

    {:noreply, socket |> assign(:bots, bots) |> assign(:bot_changeset, bot_changeset)}
  end

  def create_bot(params, socket) do
    case Bots.create_bot(socket.assigns.user, params) do
      {:ok, _bot} ->
        bot_changeset = Bots.change_bot(%Bot{})

        {:noreply,
         socket
         |> assign(:bot_changeset, bot_changeset)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:bot_changeset, changeset)
         |> put_flash(:error, "could not create bot")}
    end
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

  def render(assigns) do
    ~F"""
    <BotModal title={"#{@action} Bot"} show={ @show_bot_dialog } hide_event="hide_dialog" changeset={ @bot_changeset } />
    <div class="columns">
      <div class="column">
        <div>
          <Button click="show_bot_dialog" color="primary" opts={role: "create_bot"}>Setup New Bot</Button>
        </div>

        <aside class="menu">
        <p class="menu-label">
          Bots
        </p>
        <ul class="menu-list">
          {#for bot <- @bots }
            <li><a :on-click="select_bot" phx-value-bot_id={bot.id} role="select_bot"> {bot.name} - {bot.uptime_status} </a></li>
          {/for}
        </ul>
        </aside>
      </div>
      <div class="column">
        <MonacoEditor id="editor"/>
      </div>

      <div class="column">
        <section class="box">
          <div>
            <Button class="button is-rounded is-primary" click="save_code"    opts={phx_value_bot: @bot_changeset.data.id, role: "save_code_#{@bot_changeset.data.id}"} disabled={!@bot_changeset.valid?}>Save</Button>
            <Button class="button is-rounded is-success" click="restart_code" opts={phx_value_bot: @bot_changeset.data.id, role: "restart_code_#{@bot_changeset.data.id}"}>Restart</Button>
            <Button class="button is-rounded is-danger"  click="stop_code"    opts={phx_value_bot: @bot_changeset.data.id, role: "stop_code_#{@bot_changeset.data.id}"}>Stop</Button>
            {@bot_changeset.data.uptime_status}
          </div>
          <XTerm id="terminal"/>
        </section>
      </div>
    </div>
    """
  end
end
