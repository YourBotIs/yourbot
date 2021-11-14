defmodule YourBotWeb.UsersController do
  use YourBotWeb, :controller
  alias YourBot.Accounts

  def show(conn, %{"id" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id(discord_user_id)
    render(conn, "show.json", %{discord_oauth: user.discord_oauth})
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
