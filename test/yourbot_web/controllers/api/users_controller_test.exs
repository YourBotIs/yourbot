defmodule YourBotWeb.UsersControllerTest do
  use YourBotWeb.ConnCase
  import YourBot.AccountsFixtures

  setup [:setup_user, :setup_discord_oauth, :setup_api_token]

  test "generate a new api token", %{conn: conn, discord_oauth: discord_oauth} do
    body =
      conn
      |> post(Routes.users_path(conn, :token, discord_oauth.discord_user_id))
      |> json_response(201)

    assert token_binary = body["data"]["token"]
    assert token = YourBot.Repo.get_by(YourBot.Accounts.APIToken, token: token_binary)
    fields = YourBot.Accounts.APIToken.fields(token)

    for {field, value} <- fields do
      assert body["data"][field] == value
    end
  end

  test "show user", %{conn: conn, discord_oauth: discord_oauth} do
    body =
      conn
      |> get(Routes.users_path(@endpoint, :show, discord_oauth.discord_user_id))
      |> json_response(200)

    assert body["data"]["discord_user_id"] == discord_oauth.discord_user_id
    assert body["data"]["avatar"] == discord_oauth.avatar
    assert body["data"]["username"] == discord_oauth.username
    assert body["data"]["discriminator"] == discord_oauth.discriminator
  end

  test "create user", %{conn: conn} do
    attrs = valid_discord_oauth_attributes()

    body =
      conn
      |> post(Routes.users_path(@endpoint, :create), %{discord_oauth: attrs})
      |> json_response(201)

    assert body["data"]["discord_user_id"] == attrs.discord_user_id
    assert body["data"]["avatar"] == attrs.avatar
    assert body["data"]["username"] == attrs.username
    assert body["data"]["discriminator"] == attrs.discriminator
  end
end
