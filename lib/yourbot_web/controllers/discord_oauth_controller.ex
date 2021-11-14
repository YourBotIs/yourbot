defmodule YourBotWeb.DiscordOAuthController do
  use YourBotWeb, :controller
  alias YourBot.Accounts
  alias YourBotWeb.UserAuth
  alias YourBotWeb.OAuth.Discord, as: OAuth
  require Logger

  def logout(conn, _) do
    YourBotWeb.UserAuth.log_out_user(conn)
  end

  def oauth(conn, %{"code" => code} = params) do
    Logger.info("Discord Oauth: #{inspect(params)}")
    client = OAuth.exchange_code(code)

    with {:ok, me} <- OAuth.me(client) do
      case Accounts.get_user_by_discord_id(me["id"]) do
        nil ->
          {:ok, %{user: user}} =
            Accounts.discord_oauth_registration(put_in(me, ["discord_user_id"], me["id"]))

          conn
          |> UserAuth.log_in_user(user, me)

        %{discord_oauth: discord_oauth} = user ->
          {:ok, _} = Accounts.update_discord_oauth(discord_oauth, me)

          conn
          |> UserAuth.log_in_user(user, me)
      end
    end
  end

  def oauth(conn, %{"error" => error, "error_description" => reason}) do
    conn
    |> put_flash(:error, "#{error} #{reason}")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
