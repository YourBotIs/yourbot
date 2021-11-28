defmodule YourBotWeb.EnvironmentVariableController do
  use YourBotWeb, :controller

  alias YourBot.Bots
  alias YourBot.Bots.Project

  action_fallback YourBotWeb.FallbackController

  use PhoenixSwagger

  def swagger_definitions do
    %{
      EnvironmentVariable:
        swagger_schema do
          title("EnvironmentVariable")
          description("Describes an env var")

          properties do
            key(:string, "Unique name of the variable", required: true)
            value(:string, "secret value", required: true)
          end

          example(%{
            key: "SECRET_TOKEN",
            value: "SUPER.SECRET.VALUE"
          })
        end,
      CreateEnvironmentVariable:
        swagger_schema do
          title("Create env var")
          description("Params for creating an env var")

          properties do
            environment_variable(
              Schema.new do
                properties do
                  key(:string, "Unique name of the variable", required: true)
                  value(:string, "secret value", required: true)
                end
              end
            )
          end
        end
    }
  end

  swagger_path :index do
    get("/bots/{bot_id}/environment_variables")
    description("list env vars for a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    response(200, %{data: Schema.array(:EnvironmentVariable)})
  end

  def index(conn, %{"bots_id" => bot_id}) do
    bot = Bots.get_bot(bot_id)
    project = Project.load_project(bot.project)
    render(conn, "index.json", environment_variables: project.environment_variables)
  end

  swagger_path :create do
    post("/bots/{bot_id}/environment_variables/")
    description("create a env var")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)

    parameter(
      :environment_variable,
      :body,
      Schema.ref(:CreateEnvironmentVariable),
      "var to create",
      required: true
    )

    response(200, %{data: Schema.ref(:EnvironmentVariable)})
  end

  def create(conn, %{"bots_id" => bot_id, "environment_variable" => params}) do
    bot = Bots.get_bot(bot_id)

    with {:ok, environment_variable} <- Project.create_environment_variable(bot.project, params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.bots_environment_variable_path(conn, :show, bot_id, environment_variable)
      )
      |> render("show.json", environment_variable: environment_variable)
    end
  end

  swagger_path :show do
    get("/bots/{bot_id}/environment_variables/{environment_variable_id}")
    description("show an env var for a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    parameter(:environment_variable_id, :path, :string, "Environment Variable ID", required: true)
    response(200, %{data: Schema.array(:EnvironmentVariable)})
  end

  def show(conn, %{"bots_id" => bot_id, "id" => environment_variable_id}) do
    bot = Bots.get_bot(bot_id)
    environment_variable = Project.get_environment_variable(bot.project, environment_variable_id)
    render(conn, "show.json", %{environment_variable: environment_variable})
  end

  swagger_path :update do
    patch("/bots/{bot_id}/environment_variables/{environment_variable_id}")
    description("Update a env var")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    parameter(:environment_variable_id, :path, :string, "Environment Variable ID", required: true)

    parameter(
      :environment_variable,
      :body,
      Schema.ref(:CreateEnvironmentVariable),
      "var to update",
      required: true
    )

    response(200, %{data: Schema.array(:EnvironmentVariable)})
  end

  def update(conn, %{
        "bots_id" => bot_id,
        "id" => environment_variable_id,
        "environment_variable" => params
      }) do
    bot = Bots.get_bot(bot_id)
    environment_variable = Project.get_environment_variable(bot.project, environment_variable_id)

    with {:ok, environment_variable} <-
           Project.update_environment_variable(bot.project, environment_variable, params) do
      render(conn, "show.json", environment_variable: environment_variable)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/bots/{bot_id}/environment_variables/{environment_variable_id}")
    description("delete an env var")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to delete", required: true)
    parameter(:environment_variable_id, :path, :string, "Environment Variable ID", required: true)
    response(204, nil)
  end

  def delete(conn, %{"bots_id" => bot_id, "id" => environment_variable_id}) do
    bot = Bots.get_bot(bot_id)
    environment_variable = Project.get_environment_variable(bot.project, environment_variable_id)

    with {:ok, _environment_variable} <-
           Project.delete_environment_variable(bot.project, environment_variable) do
      send_resp(conn, :no_content, "")
    end
  end
end
