defmodule YourBotWeb.BotLive do
  use Surface.LiveView

  alias YourBot.Accounts
  alias MonacoEditor
  alias YourBot.Bots
  alias YourBot.Bots.Bot
  alias YourBot.Bots.Project
  alias YourBot.Bots.Project.File
  alias YourBot.Bots.Project.EnvironmentVariable

  alias SurfaceBulma.Button
  alias YourBotWeb.Components.BotModal
  alias YourBotWeb.Components.EnvVarModal
  alias YourBotWeb.Components.BotEventsModal

  alias YourBot.Editor.Presence
  require Logger

  data show_bot_dialog, :boolean, default: false
  data show_env_var_dialog, :boolean, default: false
  data show_bot_events_dialog, :boolean, default: false
  data show_bot_select_dialog, :boolean, default: false

  def mount(_, %{"user_token" => token}, socket) do
    user = Accounts.get_user_by_session_token(token)
    discord_oauth = Accounts.get_discord_oauth(user.discord_oauth_id)

    bots =
      Bots.list_bots(user)
      |> Enum.map(fn bot -> sync_bot(bot, nil) end)

    bot_changeset = Bots.change_bot(%Bot{})
    environment_variable_changeset = Project.change_environment_variable(%EnvironmentVariable{})
    file_changeset = Project.change_file(%File{})
    socket.endpoint.subscribe("crud:bots")
    socket.endpoint.subscribe("bots")
    # socket.endpoint.subscribe("monaco_change")
    socket.endpoint.subscribe("editors")

    Presence.track(self(), "editors", socket.id, %{
      username: "#{discord_oauth.username}##{discord_oauth.discriminator}"
    })

    :ok = SocketDrano.monitor(socket)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:bots, bots)
     |> assign(:bot_changeset, bot_changeset)
     |> assign(:environment_variable_changeset, environment_variable_changeset)
     |> assign(:file_changeset, file_changeset)
     |> assign(:files, [])
     |> assign(:environment_files, [])
     |> assign(:events, [])
     |> assign(:action, :create)}
  end

  def handle_event("show_bot_dialog", _, socket) do
    bot_changeset = Bots.change_bot(socket.assigns.bot_changeset.data)

    {:noreply,
     socket
     |> assign(:show_bot_dialog, true)
     |> assign(:bot_changeset, bot_changeset)}
  end

  def handle_event("show_env_var_dialog", _, socket) do
    environment_variable_changeset = Project.change_environment_variable(%EnvironmentVariable{})

    {:noreply,
     socket
     |> assign(:show_env_var_dialog, true)
     |> assign(:action, :create)
     |> assign(:environment_variable_changeset, environment_variable_changeset)}
  end

  def handle_event("show_bot_events_dialog", _, socket) do
    events = Project.list_events(socket.assigns.bot_changeset.data.project)

    {:noreply,
     socket
     |> assign(:show_bot_events_dialog, true)
     |> assign(:events, events)}
  end

  def handle_event("hide_dialog", _, socket) do
    bots = Bots.list_bots(socket.assigns.user)

    {:noreply,
     socket
     |> assign(:bots, bots)
     |> assign(:show_bot_dialog, false)
     |> assign(:show_env_var_dialog, false)
     |> assign(:show_bot_events_dialog, false)}
  end

  def handle_event("change", %{"bot" => params}, socket) do
    case socket.assigns.action do
      :create ->
        bot_changeset =
          socket.assigns.bot_changeset.data
          |> sync_bot(nil)
          |> Bots.change_bot(params)

        {:noreply,
         socket
         |> assign(:bot_changeset, bot_changeset)}

      :edit ->
        bot_changeset =
          socket.assigns.bot_changeset.data
          |> sync_bot(nil)
          |> Bots.change_bot(params)

        {:noreply, assign(socket, :bot_changeset, bot_changeset)}
    end
  end

  def handle_event("change", %{"environment_variable" => params}, socket) do
    case socket.assigns.action do
      :create ->
        environment_variable_changeset =
          Project.change_environment_variable(%EnvironmentVariable{}, params)

        {:noreply,
         socket
         |> assign(:environment_variable_changeset, environment_variable_changeset)}

      :edit ->
        environment_variable_changeset =
          Project.change_environment_variable(
            socket.assigns.environment_variable_changeset,
            params
          )

        {:noreply,
         socket
         |> assign(:environment_variable_changeset, environment_variable_changeset)}
    end
  end

  def handle_event("save", %{"bot" => params}, socket) do
    case socket.assigns.action do
      :create ->
        create_bot(params, socket)

      :edit ->
        update_bot(socket.assigns.bot_changeset.data, params, socket)
    end
  end

  def handle_event("save", %{"environment_variable" => params}, socket) do
    case socket.assigns.action do
      :create ->
        create_environment_variable(socket.assigns.bot_changeset.data, params, socket)
    end
  end

  def handle_event("select_bot", %{"bot_id" => bot_id}, socket) do
    bot_changeset =
      Bots.get_bot(socket.assigns.user, bot_id)
      |> sync_bot(nil)
      |> Bots.change_bot()

    file_changeset =
      Project.get_entrypoint_file(bot_changeset.data.project)
      |> Project.change_file()

    files = Project.list_files(bot_changeset.data.project)

    environment_variables = Project.list_environment_variables(bot_changeset.data.project)

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
     |> assign(:file_changeset, file_changeset)
     |> assign(:files, files)
     |> assign(:environment_variables, environment_variables)
     |> assign(:action, :edit)
     |> assign(:show_bot_select_dialog, false)
     |> push_event(:monaco_load, %{value: file_changeset.data.content})}
  end

  def handle_event("show_bot_select_dialog", _, socket) do
    {:noreply,
     socket
     |> assign(:show_bot_select_dialog, !socket.assigns[:show_bot_select_dialog])}
  end

  def handle_event("monaco_change", %{"value" => code}, socket) do
    changeset = Project.change_file(socket.assigns.file_changeset.data, %{content: code})

    {:noreply,
     socket
     |> assign(:file_changeset, changeset)}
  end

  def handle_event("save_code", %{}, socket) do
    if Ecto.Changeset.get_change(socket.assigns.file_changeset, :content) do
      code = socket.assigns.file_changeset.changes.content

      case Project.update_file(
             socket.assigns.bot_changeset.data.project,
             socket.assigns.file_changeset.data,
             %{content: code}
           ) do
        {:ok, file} ->
          file_changeset = Project.change_file(file)

          {:noreply,
           socket
           |> assign(:file_changeset, file_changeset)
           |> push_event(:monaco_load, %{value: code})}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("restart_code", %{"bot" => bot_id}, socket) do
    bot_changeset =
      Bots.get_bot(socket.assigns.user, bot_id) |> sync_bot(nil) |> Bots.change_bot()

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
    YourBot.Bots.get_bot(socket.assigns.user, bot_id)
    |> YourBot.BotSupervisor.terminate_child()

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{topic: "crud:bots", payload: data}, socket) do
    bots =
      Bots.list_bots(socket.assigns.user)
      |> Enum.map(fn bot -> sync_bot(bot, nil) end)

    %{id: bot_id} = socket.assigns.bot_changeset.data

    socket =
      case data[:new] do
        %{id: ^bot_id, code: code} ->
          push_event(socket, :monaco_load, %{value: code})

        _ ->
          socket
      end

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
          topic: "editors",
          event: "presence_diff",
          payload: _presence
        },
        socket
      ) do
    # online = socket.assigns.online
    {:noreply, socket}
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

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "monaco_change",
          payload: %{code: code, bot_id: bot_id, self: pid}
        },
        socket
      ) do
    correct_bot? = bot_id == socket.assigns.bot_changeset.data.id
    correct_pid? = pid != self()

    if correct_bot? && correct_pid? do
      changeset = Bots.change_bot(socket.assigns.bot_changeset.data, %{code: code})

      {:noreply,
       socket
       |> push_event(:monaco_load, %{value: code})
       |> assign(:bot_changeset, changeset)}
    else
      {:noreply, socket}
    end
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

  def update_bot(bot, params, socket) do
    case Bots.update_bot(bot, params) do
      {:ok, bot} ->
        bot_changeset = Bots.change_bot(sync_bot(bot, nil), params)
        {:noreply, assign(socket, :bot_changeset, bot_changeset)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:bot_changeset, changeset)
         |> put_flash(:error, "could not create bot")}
    end
  end

  def create_environment_variable(bot, params, socket) do
    case Project.create_environment_variable(bot.project, params) do
      {:ok, _} ->
        environment_variable_changeset =
          Project.change_environment_variable(%EnvironmentVariable{})

        {:noreply,
         socket
         |> assign(:environment_variable_changeset, environment_variable_changeset)}

      {:error, environment_variable_changeset} ->
        {:noreply,
         socket
         |> assign(:environment_variable_changeset, environment_variable_changeset)}
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
    <EnvVarModal title={"Environment variables"} show={ @show_env_var_dialog} hide_event="hide_dialog" changeset={@environment_variable_changeset} />
    <BotEventsModal title={"Bot Events"} show={ @show_bot_events_dialog } hide_event="hide_dialog" events={@events} />
    <nav class="navbar" role="navigation" aria-label="dropdown navigation">
      <div class="navbar-menu">
        <div class="navbar-start">
          <div class="navbar-item has-dropdown is-active">
            <a :on-click="show_bot_select_dialog" class="navbar-link">Bots</a>
            <div class="navbar-dropdown" :if={@show_bot_select_dialog}>
              {#for bot <- @bots }
                <a :on-click="select_bot" phx-value-bot_id={bot.id} role="select_bot" class="navbar-item"> {bot.name} - {bot.uptime_status} </a>
              {/for}
            </div>
          </div>
          <div class="navbar-item" :if={@bot_changeset.data.id}>
            {@bot_changeset.data.name}
            <div class="tabs is-small">
              <ul>
                <li class="is-active"><a> client.py </a></li>
                {#for file <- tl(@files) }
                  <li class="" :on-click=""><a> {file.name} </a></li>
                {/for}
                <a>
                  <span class="icon is-small" :on-click="create_file"><i class="fas fa-plus" aria-hidden="true"></i></span>
                </a>
              </ul>
            </div>
          </div>
        </div>
        <div class="navbar-item" :if={@bot_changeset.data.id}>
          <Button class="button is-rounded is-primary" click="save_code" opts={phx_value_bot: @bot_changeset.data.id, role: "save_code_#{@bot_changeset.data.id}"} disabled={!@bot_changeset.valid?}>Save</Button>
        </div>
        <div class="navbar-item" :if={@bot_changeset.data.id}>
          <Button class="button is-rounded is-success" click="restart_code" opts={phx_value_bot: @bot_changeset.data.id, role: "restart_code_#{@bot_changeset.data.id}"}>Restart</Button>
        </div>
        <div class="navbar-item" :if={@bot_changeset.data.id}>
          <Button class="button is-rounded is-danger"  click="stop_code"    opts={phx_value_bot: @bot_changeset.data.id, role: "stop_code_#{@bot_changeset.data.id}"}>Stop</Button>
        </div>
        <div class="navbar-end">
          <div class="navbar-item">
            <Button click="show_bot_dialog" color="primary" opts={role: "create_bot"}>Setup New Bot</Button>
          </div>
        </div>
      </div>
    </nav>
    <section class="block">
      <div class="columns fullcolumn">
        <div class="column">
          <MonacoEditor id="editor"/>
          <div :if={@bot_changeset.data.id}>
            {#for env_var <- @environment_variables }
              <div>
                {env_var.key} {env_var.value}
              </div>
            {/for}
          </div>
        </div>

        <div class="column is-one-quarter">
          <section class="box">
            <div>
              <Button :if={@bot_changeset.data.id} class="button is-rounded is-primary" click="show_bot_dialog" color="primary" opts={role: "edit_bot"}>Edit Bot</Button>
              <Button :if={@bot_changeset.data.id} class="button is-rounded is-primary" click="show_env_var_dialog" color="primary" opts={role: "show_env_var_dialog"}>Env Vars</Button>
              <Button :if={@bot_changeset.data.id} class="button is-rounded is-primary" click="show_bot_events_dialog" color="primary" opts={role: "show_bot_events_dialog"}>Event Log</Button>
            </div>
            <div>
              {@bot_changeset.data.uptime_status}
              <a href={"https://discord.com/developers/applications/#{@bot_changeset.data.application_id}/bot"} :if={@bot_changeset.data.id}> Discord Management Console </a>
              <a href={"https://discordapp.com/api/oauth2/authorize?client_id=#{@bot_changeset.data.application_id}&scope=bot&permissions=274877941760"} :if={@bot_changeset.data.id}> Invite the bot to a server </a>
            </div>
            <XTerm id="terminal"/>
          </section>
        </div>
      </div>
    </section>
    """
  end
end
