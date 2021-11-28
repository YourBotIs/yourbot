defmodule YourBotWeb.BotsController do
  use YourBotWeb, :controller
  alias YourBot.Bots
  alias YourBot.Bots.Project
  alias YourBot.Accounts

  action_fallback YourBotWeb.FallbackController

  use PhoenixSwagger

  def swagger_definitions do
    %{
      BotDeployStatus:
        swagger_schema do
          title("Bot deployment status")
          description("Values are changed in the websocket connection")
          enum(["live", "stop", "error"])
        end,
      Bot:
        swagger_schema do
          title("Bot")
          description("Describes a bot object")

          properties do
            name(:string, "Unique Name of the Bot", required: true)
            token(:string, "Authentication token", required: true)
            application_id(:integer, "Discord ID", required: true)
            public_key(:string, "Discord public key", required: true)
            deploy_status(:string, Schema.ref(:BotDeployStatus), required: true)
          end

          example(%{
            name: "MiataBot",
            token: "super secret",
            application_id: "123455",
            public_key: "12345"
          })
        end,
      BotEvent:
        swagger_schema do
          title("Bot Event")
          description("simple key/value log")

          properties do
            name(:string, "name of the event", required: true)
            content(:string, "content of the event", required: true)
            inserted_at(:string, "datetime", required: true)
            updated_at(:string, "datetime", required: true)
          end
        end,
      CreateBot:
        swagger_schema do
          title("Create Bot")
          description("Params for creating a bot")

          properties do
            bot(
              Schema.new do
                properties do
                  name(:string, "Unique Name of the Bot", required: true)
                  token(:string, "Authentication token", required: true)
                  application_id(:integer, "Discord ID", required: true)
                  public_key(:string, "Discord public key", required: true)
                end
              end
            )
          end

          example(%{
            bot: %{
              name: "MiataBot",
              token: "super secret",
              application_id: "123455",
              public_key: "12345"
            }
          })
        end
    }
  end

  swagger_path :index do
    get("/bots")
    description("list bots")
    security([%{Bearer: []}])
    response(200, %{data: Schema.array(:Bot)})
  end

  def index(conn, _params) do
    bots = Bots.list_bots()
    render(conn, "index.json", bots: bots)
  end

  swagger_path :create do
    post("/bots")
    description("create a bot")
    security([%{Bearer: []}])
    parameter(:bot, :body, Schema.ref(:CreateBot), "bot to create", required: true)
    response(200, %{data: Schema.ref(:Bot)})
  end

  def create(conn, %{"bot" => params, "user" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id(discord_user_id)

    with {:ok, bot} <- Bots.create_bot(user, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.bots_path(conn, :show, bot))
      |> render("show.json", bots: bot)
    end
  end

  swagger_path :update do
    patch("/bots/{bot_id}")
    description("update a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to update", required: true)
    parameter(:bot, :body, Schema.ref(:CreateBot), "bot to update", required: true)
    response(200, %{data: Schema.ref(:Bot)})
  end

  def update(conn, %{"id" => bot_id, "bot" => params}) do
    bot = Bots.get_bot(bot_id)

    with {:ok, bot} <- YourBot.Bots.update_bot(bot, params) do
      render(conn, "show.json", bots: bot)
    end
  end

  swagger_path :show do
    get("/bots/{bot_id}")
    description("update a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to update", required: true)
    response(200, %{data: Schema.ref(:Bot)})
  end

  def show(conn, %{"id" => bot_id}) do
    bot = Bots.get_bot(bot_id)
    render(conn, "show.json", bots: bot)
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/bots/{bot_id}")
    description("delete a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to delete", required: true)
    response(200, nil)
  end

  def delete(conn, %{"id" => bot_id}) do
    bot = Bots.get_bot(bot_id)

    with {:ok, _bot} <- Bots.delete_bot(bot) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :show_bots_for_user do
    get("/users/{discord_user_id}/bots")
    description("list bots")
    security([%{Bearer: []}])
    parameter(:discord_user_id, :path, :string, "User whose bots to list", required: true)
    response(200, %{data: Schema.array(:Bot)})
  end

  def show_bots_for_user(conn, %{"id" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id!(discord_user_id)
    bots = Bots.list_bots(user)
    render(conn, "index.json", bots: bots)
  end

  swagger_path :events do
    get("/bots/{bot_id}/events")
    description("list bots")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "bot whose log to view", required: true)
    response(200, %{data: Schema.array(:BotEvent)})
  end

  def events(conn, %{"bots_id" => bot_id}) do
    bot = Bots.get_bot(bot_id)
    events = Project.list_events(bot.project)
    render(conn, "index.json", events: events)
  end
end
