defmodule YourBot.Repo.Migrations.DropBotDbsTable do
  use Ecto.Migration

  def change do
    drop_if_exists index("bot_dbs", [], name: "bot_dbs_bot_id_fkey")
    drop_if_exists table("bot_dbs")
  end
end
