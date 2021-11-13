defmodule YourBotWeb.UsersController do
  use YourBotWeb, :controller
  alias YourBot.Accounts

  def show(conn, %{"id" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id(discord_user_id)
    render(conn, "show.json", %{users: user})
  end
end
