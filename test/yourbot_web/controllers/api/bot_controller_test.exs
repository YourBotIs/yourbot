defmodule YourBotWeb.BotsControllerTest do
  use YourBotWeb.ConnCase
  import YourBot.UniqueData
  import YourBot.AccountsFixtures
  import YourBot.BotFixtures

  setup [:setup_user, :setup_discord_oauth, :setup_api_token]

  test "create bot", %{discord_oauth: discord_oauth, conn: conn} do
    body =
      conn
      |> post(Routes.bots_path(@endpoint, :create), %{
        user: discord_oauth.discord_user_id,
        bot: %{
          name: unique_name("bot name"),
          application_id: unique_id(),
          public_key: unique_name("bot public_key"),
          token: unique_name("bot token")
        }
      })
      |> json_response(201)

    body["data"]["id"]
    body["data"]["code"]
    body["data"]["application_id"]
    body["data"]["public_key"]
    body["data"]["token"]
  end

  setup :setup_bot

  test "list bots", %{conn: conn, bot: bot} do
    body =
      conn
      |> get(Routes.bots_path(@endpoint, :index))
      |> json_response(200)

    assert is_list(body["data"])

    assert found = Enum.find(body["data"], fn %{"id" => bot_id} -> bot_id == bot.id end)

    assert found["code"] == bot.code
    assert found["application_id"] == bot.application_id
    assert found["public_key"] == bot.public_key
    assert found["token"] == bot.token
  end

  test "update bot", %{conn: conn, bot: bot} do
    updated_name = unique_name("bot renamed")

    body =
      conn
      |> patch(Routes.bots_path(@endpoint, :update, bot), %{
        "bot" => %{
          "name" => updated_name
        }
      })
      |> json_response(200)

    assert body["data"]["code"] == bot.code
    assert body["data"]["application_id"] == bot.application_id
    assert body["data"]["public_key"] == bot.public_key
    assert body["data"]["token"] == bot.token
    assert body["data"]["name"] == updated_name
  end

  test "show bot", %{conn: conn, bot: bot} do
    body =
      conn
      |> get(Routes.bots_path(@endpoint, :show, bot))
      |> json_response(200)

    assert body["data"]["code"] == bot.code
    assert body["data"]["application_id"] == bot.application_id
    assert body["data"]["public_key"] == bot.public_key
    assert body["data"]["token"] == bot.token
    assert body["data"]["name"] == bot.name
  end

  test "delete bot", %{conn: conn, bot: bot} do
    body =
      conn
      |> delete(Routes.bots_path(@endpoint, :delete, bot))
      |> json_response(200)

    assert body["data"]["code"] == bot.code
    assert body["data"]["application_id"] == bot.application_id
    assert body["data"]["public_key"] == bot.public_key
    assert body["data"]["token"] == bot.token
    assert body["data"]["name"] == bot.name
  end
end
