defmodule YourBotWeb.UsersControllerTest do
  use YourBotWeb.ConnCase
  import YourBot.AccountsFixtures

  setup [:setup_user, :setup_discord_oauth, :setup_api_token]

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
end
