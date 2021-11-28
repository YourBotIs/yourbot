defmodule YourBot.Bots.Project do
  defmodule Container do
    @moduledoc """
    Container object for archiving all the required data
    for the sandbox runtime execute and monitor.
    """
    use Ecto.Schema

    schema "projects" do
      belongs_to :bot, YourBot.Bots.Bot
      field :uuid, :binary_id, null: false
      timestamps()
    end

    def initialize(%YourBot.Bots.Project.Container{} = container) do
      YourBot.Bots.Project.Repo.with_repo(container, fn %{pid: pid} ->
        _ =
          Ecto.Migrator.run(YourBot.Bots.Project.Repo, :up,
            all: true,
            dynamic_repo: pid,
            log: :debug,
            log_migrations_sql: :debug,
            log_migrator_sql: :debug
          )
      end)

      {:ok, container}
    end

    def path(%YourBot.Bots.Project.Container{uuid: uuid}) do
      Path.join(YourBot.Bots.Project.storage_dir(), "#{uuid}.sqlite3")
    end
  end

  @moduledoc """
  Root object for the sandbox runtime. This object is
  stored in SQLite, not postgres!
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias YourBot.Bots.Project

  schema "yourbot_project" do
    field :version, :integer, null: false
    has_many :events, Project.Event
    has_many :environment_variables, Project.EnvironmentVariable
    has_many :files, Project.File
  end

  def changeset(sandbox, attrs \\ %{}) do
    sandbox
    |> cast(attrs, [:version])
    |> validate_required([:version])
  end

  def storage_dir do
    Application.get_env(:yourbot, __MODULE__)[:storage_dir]
  end

  # Context functions

  @endpoint YourBotWeb.Endpoint

  import Ecto.Changeset
  import Ecto.Query

  alias YourBot.Bots.Project.Repo
  alias YourBot.Bots.Project
  alias YourBot.Bots.Project.File
  alias YourBot.Bots.Project.EnvironmentVariable
  alias YourBot.Bots.Project.Event

  @doc "Loads env var for a project"
  def load_project(container) do
    Repo.with_repo(container, fn _context ->
      _load_project()
    end)
  end

  defp _load_project() do
    Repo.one(Project)
    |> Repo.preload([:events, :files, :environment_variables])
  end

  def list_environment_variables(container) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _list_environment_variables(project)
    end)
  end

  def _list_environment_variables(project) do
    Repo.all(from ev in EnvironmentVariable, where: ev.project_id == ^project.id)
  end

  @doc "Create env var"
  def create_environment_variable(container, attrs \\ %{}) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _create_environment_variable(project, attrs)
    end)
  end

  defp _create_environment_variable(project, attrs) do
    changeset = change_environment_variable(%EnvironmentVariable{project_id: project.id}, attrs)

    case Repo.insert(changeset) do
      {:ok, environment_variable} ->
        @endpoint.broadcast("crud:environment_variables", "insert", %{
          new: environment_variable
        })

        {:ok, environment_variable}

      error ->
        error
    end
  end

  @doc "update an env var"
  def update_environment_variable(container, environment_variable, attrs) do
    Repo.with_repo(container, fn _context ->
      _update_environment_variable(environment_variable, attrs)
    end)
  end

  defp _update_environment_variable(environment_variable, attrs) do
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

  @doc "Delete env var"
  def delete_environment_variable(container, environment_variable) do
    Repo.with_repo(container, fn _context ->
      _delete_environment_variable(environment_variable)
    end)
  end

  defp _delete_environment_variable(environment_variable) do
    case Repo.delete(environment_variable) do
      {:ok, environment_variable} ->
        @endpoint.broadcast("crud:environment_variables", "delete", %{
          old: environment_variable
        })

        {:ok, environment_variable}

      error ->
        error
    end
  end

  @doc "Get an env var"
  def get_environment_variable(container, env_var_id) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _get_environment_variable(project, env_var_id)
    end)
  end

  defp _get_environment_variable(project, env_var_id) do
    Repo.one!(
      from ev in EnvironmentVariable,
        where: ev.project_id == ^project.id and ev.id == ^env_var_id
    )
  end

  @doc "Env var changeset"
  def change_environment_variable(environment_variable, attrs \\ %{}) do
    EnvironmentVariable.changeset(environment_variable, attrs)
  end

  @doc "Save an event in the log"
  def create_event(container, attrs \\ %{}) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _create_event(project, attrs)
    end)
  end

  defp _create_event(project, attrs) do
    Event.changeset(%Event{project_id: project.id}, attrs)
    |> Repo.insert()
  end

  @doc "List all events"
  def list_events(container) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _list_events(project)
    end)
  end

  defp _list_events(project) do
    Repo.all(from event in Event, where: event.project_id == ^project.id)
  end

  def get_entrypoint_file(container) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _get_entrypoint_file(project)
    end)
  end

  def _get_entrypoint_file(project) do
    Repo.one!(
      from file in File, where: file.project_id == ^project.id and file.name == "client.py"
    )
  end

  def list_files(container) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _list_files(project)
    end)
  end

  def _list_files(project) do
    Repo.all(from file in File, where: file.project_id == ^project.id)
  end

  def get_file(container, id) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _get_file(project, id)
    end)
  end

  defp _get_file(project, id) do
    Repo.one!(from f in File, where: f.project_id == ^project.id and f.id == ^id)
  end

  @doc "create a file on the filesystem"
  def create_file(container, attrs \\ %{}) do
    Repo.with_repo(container, fn _context ->
      project = _load_project()
      _create_file(project, attrs)
    end)
  end

  defp _create_file(project, attrs) do
    changeset = File.changeset(%File{project_id: project.id}, attrs)

    with {:ok, file} <- Repo.insert(changeset) do
      @endpoint.broadcast("crud:files", "insert", %{new: file})
      {:ok, file}
    end
  end

  @doc "File changeset"
  def change_file(file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end

  @doc "Update a file on the filesystem"
  def update_file(container, file, attrs) do
    Repo.with_repo(container, fn _context ->
      _update_file(file, attrs)
    end)
  end

  defp _update_file(file, attrs) do
    changeset = change_file(file, attrs)

    with {:ok, updated_file} <- Repo.update(changeset) do
      @endpoint.broadcast("crud:files", "update", %{new: updated_file, old: file})
      {:ok, updated_file}
    end
  end

  @doc "Delete a file from the database"
  def delete_file(container, file) do
    Repo.with_repo(container, fn _context ->
      _delete_file(file)
    end)
  end

  defp _delete_file(file) do
    with {:ok, file} <- Repo.delete(file) do
      @endpoint.broadcast("crud:files", "delete", %{old: file})
      {:ok, file}
    end
  end
end
