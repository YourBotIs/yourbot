defmodule YourBotWeb.UsersController do
  use YourBotWeb, :controller
  alias YourBot.Accounts

  use PhoenixSwagger

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          title("User")
          description("Essentially the `me` object from Discord")

          properties do
            discord_user_id(:string, "User discord id", required: true)
            username(:string, "User discord username", required: true)
            avatar(:string, "User discord avatar", required: true)
            discriminator(:string, "User discord discriminator", required: true)
          end

          example(%{
            discord_user_id: "316741621498511363",
            avatar: "fd01df5305fdb629a8333057e19bb41f",
            username: "PressY4Pie",
            discriminator: "0690"
          })
        end,
      CreateUser:
        swagger_schema do
          title("Create User")
          description("Essentially the `me` object from Discord")

          properties do
            discord_oauth(
              Schema.new do
                properties do
                  discord_user_id(:string, "User discord id", required: true)
                  username(:string, "User discord username", required: true)
                  avatar(:string, "User discord avatar", required: true)
                  discriminator(:string, "User discord discriminator", required: true)
                  email(:string, "User email", required: true)
                end
              end
            )
          end

          example(%{
            discord_oauth: %{
              discord_user_id: "316741621498511363",
              avatar: "fd01df5305fdb629a8333057e19bb41f",
              username: "PressY4Pie",
              discriminator: "0690",
              email: "konnorrigby@gmail.com"
            }
          })
        end
    }
  end

  swagger_path :show do
    get("/users/{discord_user_id}")
    description("show a user")
    security([%{Bearer: []}])
    parameter(:discord_user_id, :path, :string, "Discord ID", required: true)
    response(200, %{data: Schema.ref(:User)})
  end

  def show(conn, %{"id" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id(discord_user_id)
    render(conn, "show.json", %{discord_oauth: user.discord_oauth})
  end

  swagger_path :create do
    post("/users/")
    description("create a user")
    security([%{Bearer: []}])
    parameter(:discord_oauth, :body, Schema.ref(:CreateUser), "User to create", required: true)
    response(200, %{data: Schema.ref(:User)})
  end

  def create(conn, %{"discord_oauth" => attrs}) do
    case Accounts.discord_oauth_registration(attrs) do
      {:ok, %{discord_oauth: discord_oauth}} ->
        conn
        |> put_status(:created)
        |> render("show.json", %{discord_oauth: discord_oauth})

      {:error, :user, changeset, _changes} ->
        render(conn, "error.json", %{changeset: changeset})

      {:error, :discord_oauth, changeset, _changes} ->
        render(conn, "error.json", %{changeset: changeset})
    end
  end
end
