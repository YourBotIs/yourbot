defmodule YourBot.Bots do
  import Ecto.Changeset, warn: false
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias YourBot.Repo, warn: false
  @endpoint YourBotWeb.Endpoint

  alias YourBot.Bots.{Bot, BotUser}

  def list_bots(user) do
    bot_ids =
      Repo.all(
        from bot_user in BotUser,
          where: bot_user.user_id == ^user.id,
          distinct: bot_user.bot_id,
          select: bot_user.bot_id
      )

    Repo.all(from bot in Bot, where: bot.id in ^bot_ids)
  end

  def get_bot(id) do
    bot = Repo.get!(Bot, id)
    %{body: body} = ExAws.S3.get_object("bots", "#{bot.id}/client.py") |> ExAws.request!()
    %{bot | code: body}
  end

  def create_bot(user, attrs \\ %{}) do
    multi =
      Multi.new()
      |> Multi.insert(:bot, fn _ ->
        change_bot(%Bot{}, attrs)
      end)
      |> Multi.insert(:bot_user, fn %{bot: %{id: bot_id}} ->
        change(%BotUser{bot_id: bot_id, user_id: user.id}, %{user_id: user.id, bot_id: bot_id})
      end)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot}} ->
        @endpoint.broadcast("crud:bots", "insert", %{new: bot})
        code = Bot.code_template(bot)
        {:ok, sync_code!(bot, code)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_bot(bot, attrs) do
    changeset = change_bot(bot, attrs)

    case Repo.update(changeset) do
      {:ok, updated_bot} ->
        @endpoint.broadcast!("crud:bots", "update", %{new: updated_bot, old: bot})
        {:ok, sync_code!(bot, bot.code)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_bot(bot) do
    bot_users_query = from bot_user in BotUser, where: bot_user.bot_id == ^bot.id
    bot_changeset = change_bot(bot)

    multi =
      Multi.new()
      |> Multi.delete_all(:bot_users, bot_users_query)
      |> Multi.delete(:bot, bot_changeset)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot}} ->
        ExAws.S3.delete_object("bots", "#{bot.id}/client.py")
        |> ExAws.request!()

        @endpoint.broadcast("crud:bots", "delete", %{old: bot})
        {:ok, bot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_bot(bot, attrs \\ %{}) do
    Bot.changeset(bot, attrs)
  end

  def sync_code!(bot, code) do
    request = ExAws.S3.put_object("bots", "#{bot.id}/client.py", code)
    _ = ExAws.request!(request)
    %{bot | code: code}
  end
end
