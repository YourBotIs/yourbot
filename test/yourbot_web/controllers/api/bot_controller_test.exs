defmodule YourBotWeb.BotsControllerTest do
  use YourBotWeb.ConnCase
  import YourBot.UniqueData
  import YourBot.AccountsFixtures
  import YourBot.BotFixtures
  import ExUnit.CaptureIO

  setup [:setup_user, :setup_discord_oauth, :setup_api_token]

  test "create bot", %{discord_oauth: discord_oauth, conn: conn} do
    # capture_io here for the same reason as botfixtures. See that for more info
    capture_io(:stderr, fn ->
      body =
        conn
        |> post(Routes.bots_path(conn, :create), %{
          user: discord_oauth.discord_user_id,
          bot: %{
            name: unique_name("bot name"),
            application_id: unique_id(),
            public_key: unique_name("bot public_key"),
            token: unique_name("bot token")
          }
        })
        |> json_response(201)

      send(self(), {:block_result, body})
    end)

    assert_received {:block_result, body}

    body["data"]["id"]
    body["data"]["application_id"]
    body["data"]["public_key"]
    body["data"]["token"]
  end

  setup :setup_bot

  test "list bots", %{conn: conn, bot: bot} do
    body =
      conn
      |> get(Routes.bots_path(conn, :index))
      |> json_response(200)

    assert is_list(body["data"])

    assert found = Enum.find(body["data"], fn %{"id" => bot_id} -> bot_id == bot.id end)

    assert found["application_id"] == bot.application_id
    assert found["public_key"] == bot.public_key
    assert found["token"] == bot.token
  end

  test "update bot", %{conn: conn, bot: bot} do
    updated_name = unique_name("bot renamed")

    body =
      conn
      |> patch(Routes.bots_path(conn, :update, bot), %{
        "bot" => %{
          "name" => updated_name
        }
      })
      |> json_response(200)

    assert body["data"]["application_id"] == bot.application_id
    assert body["data"]["public_key"] == bot.public_key
    assert body["data"]["token"] == bot.token
    assert body["data"]["name"] == updated_name
  end

  test "show bot", %{conn: conn, bot: bot} do
    body =
      conn
      |> get(Routes.bots_path(conn, :show, bot))
      |> json_response(200)

    assert body["data"]["application_id"] == bot.application_id
    assert body["data"]["public_key"] == bot.public_key
    assert body["data"]["token"] == bot.token
    assert body["data"]["name"] == bot.name
  end

  test "delete bot", %{conn: conn, bot: bot} do
    conn = delete(conn, Routes.bots_path(conn, :delete, bot))
    assert response(conn, 204)

    assert_error_sent 404, fn ->
      get(conn, Routes.bots_path(conn, :show, bot))
    end
  end

  test "lists bots for a user", %{conn: conn, discord_oauth: discord_oauth, bot: bot} do
    conn = get(conn, Routes.bots_path(conn, :show_bots_for_user, discord_oauth.discord_user_id))
    assert body = json_response(conn, 200)
    assert is_list(body["data"])

    assert Enum.find(body["data"], fn %{"id" => id} ->
             id == bot.id
           end)
  end

  test "list events for a bot", %{conn: conn, bot: bot} do
    conn = get(conn, Routes.bots_bots_path(conn, :events, bot))
    assert body = json_response(conn, 200)
    assert is_list(body["data"])
  end

  test "import/export", %{conn: conn, bot: bot, discord_oauth: discord_oauth} do
    # export the file
    conn = get(conn, Routes.bots_bots_path(conn, :export, bot))
    filename = "#{bot.name}.sqlite3"

    # save it locally
    :ok = File.write!("storage/test/db/#{filename}", conn.resp_body)

    # delete the bot
    conn = delete(conn, Routes.bots_path(conn, :delete, bot))

    upload = %Plug.Upload{path: "storage/test/db/#{filename}", filename: filename}

    # upload the exported bot
    conn =
      post(conn, Routes.bots_path(conn, :import), %{
        user: discord_oauth.discord_user_id,
        bot: upload
      })

    File.rm!("storage/test/db/#{filename}")
    assert body = json_response(conn, 201)
    assert body["data"]["name"] == bot.name
  end
end
