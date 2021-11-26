defmodule YourBot.Bots do
  import Ecto.Changeset, warn: false
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias YourBot.Repo, warn: false
  @endpoint YourBotWeb.Endpoint

  alias YourBot.Bots.{Bot, BotUser, DB, File}

  def migrate_bot(%Bot{files: []} = bot) do
    bot = load_code(bot, :legacy)
    file = Repo.insert!(%File{bot_id: bot.id, name: "client.py"})
    # uuids are generated after insert. Load it back again
    file = Repo.get!(File, file.id)
    sync_code!(bot, file, bot.code)
  end

  def create_file(bot, attrs \\ %{}) do
    changeset = File.changeset(%File{bot_id: bot.id}, attrs)

    case Repo.insert(changeset) do
      {:ok, file} ->
        file = Repo.get!(File, file.id)
        @endpoint.broadcast("crud:files", "insert", %{new: file})
        sync_code!(bot, file, get_change(changeset, :code, ""))
        {:ok, file}

      error ->
        error
    end
  end

  def delete_file(file) do
    case Repo.delete(file) do
      {:ok, file} ->
        @endpoint.broadcast("crud:files", "delete", %{old: file})

        ExAws.S3.delete_object("bots", file.uuid)
        |> ExAws.request!()

      error ->
        error
    end
  end

  def list_bots do
    Repo.all(Bot)
    |> Repo.preload([:environment_variables, :db, :files])
    |> Enum.map(&load_code(&1, :default))
  end

  def list_started_bots() do
    Repo.all(from b in Bot, where: b.deploy_status != :stop)
    |> Repo.preload([:environment_variables, :db, :files])
    |> Enum.map(&load_code(&1, :default))
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
    |> Repo.preload([:environment_variables, :db, :files])
    |> Enum.map(&load_code(&1, :default))
  end

  def get_bot(user, bot_id) do
    Repo.one!(
      from bot_user in BotUser,
        where: bot_user.user_id == ^user.id and bot_user.bot_id == ^bot_id
    )
    |> Repo.preload(bot: [:environment_variables, :db, :files])
    |> Map.fetch!(:bot)
    |> load_code(:default)
  end

  def get_bot(id) do
    Repo.get!(Bot, id)
    |> Repo.preload([:environment_variables, :db, :files])
    |> load_code(:default)
  end

  def load_code(bot, :legacy) do
    %{body: body} = ExAws.S3.get_object("bots", "client.py") |> ExAws.request!()
    %{bot | code: body}
  end

  def load_code(bot, :default) do
    [%{name: "client.py"} = file | _] = bot.files
    load_code(bot, file)
  end

  def load_code(bot, file) do
    %{body: body} = ExAws.S3.get_object("bots", file.uuid) |> ExAws.request!()
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
      |> Multi.insert(:db, fn %{bot: %{id: bot_id}} ->
        change(%DB{bot_id: bot_id}, %{bot_id: bot_id})
      end)
      |> Multi.insert(:file, fn %{bot: %{id: bot_id}} ->
        change(%File{bot_id: bot_id, name: "client.py"})
      end)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot, file: file}} ->
        bot = Repo.preload(bot, [:environment_variables, :db, :files])
        user = Repo.preload(user, [:discord_oauth])
        code = Bot.code_template(bot, user)
        bot = sync_code!(bot, file, code)
        bot = sync_db!(bot)
        @endpoint.broadcast("crud:bots", "insert", %{new: bot})
        {:ok, bot}

      {:error, :bot, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def update_bot(bot, attrs) do
    changeset = change_bot(bot, attrs)

    case Repo.update(changeset) do
      {:ok, updated_bot} ->
        updated_bot = Repo.preload(updated_bot, [:environment_variables])
        @endpoint.broadcast!("crud:bots", "update", %{new: updated_bot, old: bot})
        {:ok, bot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_bot_deploy_status(bot, status) do
    changeset = Bot.deploy_changeset(bot, status)
    updated_bot = Repo.update!(changeset) |> Repo.preload([:environment_variables])
    @endpoint.broadcast!("crud:bots", "update", %{new: updated_bot, old: bot})
    bot
  end

  def delete_bot(bot) do
    bot_users_query = from bot_user in BotUser, where: bot_user.bot_id == ^bot.id
    bot_env_vars_query = from ev in YourBot.Bots.EnvironmentVariable, where: ev.bot_id == ^bot.id
    bot_db_query = from db in DB, where: db.bot_id == ^bot.id
    bot_files_query = from file in File, where: file.bot_id == ^bot.id
    bot_changeset = change_bot(bot)

    multi =
      Multi.new()
      |> Multi.delete_all(:bot_users, bot_users_query)
      |> Multi.delete_all(:bot_environment_variables, bot_env_vars_query)
      |> Multi.delete_all(:bot_db, bot_db_query)
      |> Multi.delete_all(:bot_files, bot_files_query)
      |> Multi.delete(:bot, bot_changeset)

    case Repo.transaction(multi) do
      {:ok, %{bot: bot, bot_files: files}} ->
        for file <- files do
          ExAws.S3.delete_object("bots", file.uuid)
          |> ExAws.request!()
        end

        @endpoint.broadcast("crud:bots", "delete", %{old: bot})
        {:ok, bot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def regenerate_code(bot, user) do
    bot = Repo.preload(bot, [:environment_variables, :db, :files])
    user = Repo.preload(user, [:discord_oauth])
    code = Bot.code_template(bot, user)
    %{name: "client.py"} = file = List.first(bot.files)
    updated_bot = bot |> sync_code!(file, code) |> sync_db!()
    @endpoint.broadcast("crud:bots", "update", %{new: updated_bot, old: bot})
    {:ok, bot}
  end

  def change_bot(bot, attrs \\ %{}) do
    Bot.changeset(bot, attrs)
  end

  def sync_code!(bot, file, code) do
    request = ExAws.S3.put_object("bots", file.uuid, code)
    _ = ExAws.request!(request)
    %{bot | code: code}
  end

  def sync_db!(bot) do
    _ = DB.initialize(bot.db)
    bot
  end

  def create_environment_variable(bot, attrs \\ %{}) do
    changeset =
      change_environment_variable(%YourBot.Bots.EnvironmentVariable{bot_id: bot.id}, attrs)

    case Repo.insert(changeset) do
      {:ok, environment_variable} ->
        @endpoint.broadcast("crud:bots:environment_variables", "insert", %{
          new: environment_variable
        })

        {:ok, environment_variable}

      error ->
        error
    end
  end

  def update_environment_variable(environment_variable, attrs) do
    changeset = change_environment_variable(environment_variable, attrs)

    case Repo.update(changeset) do
      {:ok, updated_environment_variable} ->
        @endpoint.broadcast("crud:bots:environment_variables", "update", %{
          new: updated_environment_variable,
          old: environment_variable
        })

        {:ok, updated_environment_variable}

      error ->
        error
    end
  end

  def delete_environment_variable(environment_variable) do
    case Repo.delete(environment_variable) do
      {:ok, environment_variable} ->
        @endpoint.broadcast("crud:bots:environment_variables", "delete", %{
          old: environment_variable
        })

        {:ok, environment_variable}

      error ->
        error
    end
  end

  def get_environment_variable(bot, env_var_id) do
    Repo.one!(
      from ev in YourBot.Bots.EnvironmentVariable,
        where: ev.bot_id == ^bot.id and ev.id == ^env_var_id
    )
  end

  def change_environment_variable(environment_variable, attrs \\ %{}) do
    YourBot.Bots.EnvironmentVariable.changeset(environment_variable, attrs)
  end

  def create_event(bot, name, content) do
    %{db: db} = Repo.preload(bot, [:db])
    path = DB.path(db)

    DB.Repo.with_repo(path, fn %{repo: repo} ->
      repo.insert(%DB.Event{name: name, content: content})
    end)
  end

  def list_events(bot) do
    %{db: db} = Repo.preload(bot, [:db])
    path = DB.path(db)

    DB.Repo.with_repo(path, fn %{repo: repo} ->
      repo.all(DB.Event)
    end)
  end
end
