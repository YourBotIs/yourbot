defmodule YourBot.Bots do
  import Ecto.Changeset, warn: false
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias YourBot.Repo, warn: false
  @endpoint YourBotWeb.Endpoint

  alias YourBot.Bots.{Bot, BotUser, Project}

  def list_bots do
    Repo.all(Bot)
    |> Repo.preload([:project])
  end

  def list_started_bots() do
    Repo.all(from b in Bot, where: b.deploy_status != :stop)
    |> Repo.preload([:project])
  end

  def list_bots(user) do
    bot_ids =
      Repo.all(
        from bot_user in BotUser,
          where: bot_user.user_id == ^user.id,
          distinct: bot_user.bot_id,
          select: bot_user.bot_id
      )

    Repo.all(from bot in Bot, where: bot.id in ^bot_ids)
    |> Repo.preload([:project])
  end

  def get_bot(user, bot_id) do
    Repo.one!(
      from bot_user in BotUser,
        where: bot_user.user_id == ^user.id and bot_user.bot_id == ^bot_id
    )
    |> Repo.preload(bot: [:project])
    |> Map.fetch!(:bot)
  end

  def get_bot(id) do
    Repo.get!(Bot, id)
    |> Repo.preload([:project])
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
      |> Multi.insert(:project_container_insert, fn %{bot: %{id: bot_id}} ->
        change(%Project.Container{bot_id: bot_id}, %{bot_id: bot_id})
      end)
      |> Multi.run(:project_container, fn repo, %{project_container_insert: %{id: id}} ->
        {:ok, repo.get(Project.Container, id)}
      end)
      |> Multi.run(:initialize_project, fn _repo, %{project_container: container} ->
        Project.Container.initialize(container)
      end)
      |> Multi.run(:entrypoint, fn _repo, %{bot: bot, project_container: container} ->
        content = Bot.code_template(bot, user)
        Project.create_file(container, %{name: "client.py", content: content})
      end)
      |> Multi.run(:env_vars, fn _repo, %{bot: bot, project_container: container} ->
        env_vars = [
          {"DISCORD_TOKEN", bot.token},
          {"DISCORD_PUBLIC_KEY", bot.public_key},
          {"DISCORD_CLIENT_ID", to_string(bot.application_id)},
          {"DISCORD_APPLICATION_ID", to_string(bot.application_id)}
        ]

        vars =
          for {key, value} <- env_vars do
            Project.create_environment_variable(container, %{key: key, value: value})
          end

        {:ok, vars}
      end)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot, initialize_project: project}} ->
        @endpoint.broadcast("crud:bots", "insert", %{new: %{bot | project: project}})
        {:ok, %{bot | project: project}}

      {:error, :bot, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def update_bot(bot, attrs) do
    changeset = change_bot(bot, attrs)

    case Repo.update(changeset) do
      {:ok, updated_bot} ->
        @endpoint.broadcast!("crud:bots", "update", %{new: updated_bot, old: bot})
        {:ok, updated_bot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_bot_deploy_status(bot, status) do
    changeset = Bot.deploy_changeset(bot, status)
    updated_bot = Repo.update!(changeset)
    @endpoint.broadcast!("crud:bots", "update", %{new: updated_bot, old: bot})
    bot
  end

  def delete_bot(bot) do
    bot_users_query = from bot_user in BotUser, where: bot_user.bot_id == ^bot.id
    bot_project_query = from project in Project.Container, where: project.bot_id == ^bot.id
    bot_changeset = change_bot(bot)

    multi =
      Multi.new()
      |> Multi.delete_all(:bot_users, bot_users_query)
      |> Multi.delete_all(:bot_project, bot_project_query)
      |> Multi.delete(:bot, bot_changeset)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot}} ->
        @endpoint.broadcast("crud:bots", "delete", %{old: bot})
        {:ok, bot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_bot(bot, attrs \\ %{}) do
    Bot.changeset(bot, attrs)
  end
end
