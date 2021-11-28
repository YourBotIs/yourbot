defmodule YourBot.Bots.Project.Repo.Migrations.AddYourbotProjectTable do
  use Ecto.Migration

  def change do
    create table(:yourbot_project, primary_key: false) do
      add :id, :tinyint, null: false, default: 0, primary_key: true
      add :version, :integer, default: 0
      timestamps()
    end

    execute """
    CREATE TRIGGER yourbot_project_no_insert
    BEFORE INSERT ON yourbot_project
    WHEN (SELECT COUNT(*) FROM yourbot_project) >= 1   -- limit here
    BEGIN
        SELECT RAISE(FAIL, 'Only One Project may exist');
    END;
    """,
    """
    DROP TRIGGER 'yourbot_project_no_insert';
    """

    now = NaiveDateTime.to_iso8601(NaiveDateTime.utc_now())

    execute """
    INSERT INTO yourbot_project(id, inserted_at, updated_at) VALUES(0, \'#{now}\', \'#{now}\');
    """,
    """
    DELETE FROM yourbot_project;
    """
  end
end
