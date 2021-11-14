defmodule YourBotWeb.BotsController do
  use YourBotWeb, :controller
  alias YourBot.Bots
  alias YourBot.Accounts

  use PhoenixSwagger

  def swagger_definitions do
    %{
      Bot:
        swagger_schema do
          title("Bot")
          description("Describes a bot object")

          properties do
            name(:string, "Unique Name of the Bot", required: true)
            token(:string, "Authentication token", required: true)
            application_id(:integer, "Discord ID", required: true)
            public_key(:string, "Discord public key", required: true)
            code(:string, "Python code", required: true)
          end

          example(%{
            name: "MiataBot",
            token: "super secret",
            application_id: "123455",
            public_key: "12345",
            code: "print('hello, world')"
          })
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
                  code(:string, "Python code", required: true)
                end
              end
            )
          end

          example(%{
            bot: %{
              name: "MiataBot",
              token: "super secret",
              application_id: "123455",
              public_key: "12345",
              code: "print('hello, world')"
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

    case Bots.create_bot(user, params) do
      {:ok, bot} ->
        conn
        |> put_status(:created)
        |> render("show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
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

    case YourBot.Bots.update_bot(bot, params) do
      {:ok, bot} ->
        conn
        |> render("show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
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
    description("update a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to update", required: true)
    response(200, %{data: Schema.ref(:Bot)})
  end

  def delete(conn, %{"id" => bot_id}) do
    bot = Bots.get_bot(bot_id)

    case Bots.delete_bot(bot) do
      {:ok, bot} ->
        render(conn, "show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end
end
