defmodule YourBotWeb.FileController do
  use YourBotWeb, :controller

  alias YourBot.Bots
  alias YourBot.Bots.Project

  action_fallback YourBotWeb.FallbackController

  use PhoenixSwagger

  def swagger_definitions do
    %{
      File:
        swagger_schema do
          title("File")
          description("Describes a file")

          properties do
            name(:string, "Unique name of the file", required: true)
            content(:string, "content of the file", required: true)
            uuid(:string, "unique id", required: true)
          end

          example(%{
            name: "client.py",
            content: "print('hello, world')",
            uuid: "1503f7f7-1d90-4619-b969-e4ca9e8c1b45"
          })
        end,
      CreateFile:
        swagger_schema do
          title("Create file")
          description("Params for creating a file")

          properties do
            file(
              Schema.new do
                properties do
                  name(:string, "Unique name of the file", required: true)
                  content(:string, "content of the file", required: true)
                end
              end
            )
          end
        end
    }
  end

  swagger_path :index do
    get("/bots/{bot_id}/files")
    description("list files for a bot project")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    response(200, %{data: Schema.array(:File)})
  end

  def index(conn, %{"bots_id" => bot_id}) do
    bot = Bots.get_bot(bot_id)
    project = Project.load_project(bot.project)
    render(conn, "index.json", files: project.files)
  end

  swagger_path :create do
    post("/bots/{bot_id}/files/")
    description("create a file")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)

    parameter(
      :file,
      :body,
      Schema.ref(:CreateFile),
      "File to create",
      required: true
    )

    response(200, %{data: Schema.ref(:File)})
  end

  def create(conn, %{"bots_id" => bot_id, "file" => params}) do
    bot = Bots.get_bot(bot_id)

    with {:ok, file} <- Project.create_file(bot.project, params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.bots_file_path(conn, :show, bot_id, file)
      )
      |> render("show.json", file: file)
    end
  end

  swagger_path :show do
    get("/bots/{bot_id}/file/{file_id}")
    description("show an env var for a bot")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    parameter(:file_id, :path, :string, "File ID", required: true)
    response(200, %{data: Schema.array(:File)})
  end

  def show(conn, %{"bots_id" => bot_id, "id" => file_id}) do
    bot = Bots.get_bot(bot_id)
    file = Project.get_file(bot.project, file_id)
    render(conn, "show.json", %{file: file})
  end

  swagger_path :update do
    patch("/bots/{bot_id}/files/{file_id}")
    description("Update a file")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot ID to use", required: true)
    parameter(:file_id, :path, :string, "File ID", required: true)

    parameter(
      :environment_variable,
      :body,
      Schema.ref(:CreateFile),
      "var to update",
      required: true
    )

    response(200, %{data: Schema.array(:File)})
  end

  def update(conn, %{
        "bots_id" => bot_id,
        "id" => file_id,
        "file" => params
      }) do
    bot = Bots.get_bot(bot_id)
    file = Project.get_file(bot.project, file_id)

    with {:ok, file} <- Project.update_file(bot.project, file, params) do
      render(conn, "show.json", file: file)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/bots/{bot_id}/files/{file_id}")
    description("delete an env var")
    security([%{Bearer: []}])
    parameter(:bot_id, :path, :string, "Bot to delete", required: true)
    parameter(:file_id, :path, :string, "Environment Variable ID", required: true)
    response(204, nil)
  end

  def delete(conn, %{"bots_id" => bot_id, "id" => file_id}) do
    bot = Bots.get_bot(bot_id)
    file = Project.get_file(bot.project, file_id)

    with {:ok, _file} <-
           Project.delete_file(bot.project, file) do
      send_resp(conn, :no_content, "")
    end
  end
end
