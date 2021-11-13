defmodule YourBotWeb.BotsController do
  use YourBotWeb, :controller
  alias YourBot.Bots
  alias YourBot.Accounts

  def index(conn, _params) do
    bots = Bots.list_bots()
    render(conn, "index.json", bots: bots)
  end

  def create(conn, %{"bot" => params, "user" => discord_user_id}) do
    user = Accounts.get_user_by_discord_id(discord_user_id)

    case Bots.create_bot(user, params) do
      {:ok, bot} ->
        conn
        |> put_status(:created)
        |> render("show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => bot_id, "bot" => params}) do
    bot = Bots.get_bot(bot_id)

    case YourBot.Bots.update_bot(bot, params) do
      {:ok, bot} ->
        conn
        |> render("show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => bot_id}) do
    bot = Bots.get_bot(bot_id)
    render(conn, "show.json", bots: bot)
  end

  def delete(conn, %{"id" => bot_id}) do
    bot = Bots.get_bot(bot_id)

    case Bots.delete_bot(bot) do
      {:ok, bot} ->
        render(conn, "show.json", bots: bot)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end
end
