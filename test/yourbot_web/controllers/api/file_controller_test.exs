defmodule YourBotWeb.FileControllerTest do
  use YourBotWeb.ConnCase
  import YourBot.UniqueData
  import YourBot.AccountsFixtures
  import YourBot.BotFixtures
  import YourBot.FileFixtures

  setup [:setup_user, :setup_discord_oauth, :setup_api_token, :setup_bot]

  test "list files", %{conn: conn, bot: bot} do
    body =
      conn
      |> get(Routes.bots_file_path(conn, :index, bot))
      |> json_response(200)

    assert is_list(body["data"])

    assert Enum.find(body["data"], fn file ->
             file["name"] == "client.py"
           end)
  end

  test "create file", %{conn: conn, bot: bot} do
    params = %{
      "name" => "file2.py",
      "content" => "# Hello, World!"
    }

    body =
      conn
      |> post(Routes.bots_file_path(conn, :create, bot), %{"file" => params})
      |> json_response(201)

    assert body["data"]["name"] == "file2.py"
    assert body["data"]["content"] == "# Hello, World!"
  end

  setup :setup_project_file

  test "show file", %{conn: conn, bot: bot, project_file: file} do
    body =
      conn
      |> get(Routes.bots_file_path(conn, :show, bot, file))
      |> json_response(200)

    assert body["data"]["name"] == file.name
    assert body["data"]["content"] == file.content
  end

  test "update file", %{conn: conn, bot: bot, project_file: file} do
    updated_name = unique_name("filerenamed")

    params = %{
      "name" => updated_name
    }

    body =
      conn
      |> patch(Routes.bots_file_path(conn, :update, bot, file), %{"file" => params})
      |> json_response(200)

    assert body["data"]["name"] == updated_name
  end

  test "delete file", %{conn: conn, bot: bot, project_file: file} do
    conn = delete(conn, Routes.bots_file_path(conn, :delete, bot, file))
    assert response(conn, 204)

    assert_error_sent 404, fn ->
      get(conn, Routes.bots_file_path(conn, :show, bot, file))
    end
  end
end
