defmodule YourBot.Bots.File do
  @moduledoc "Represents a single file. Folders are implicit"
  use Ecto.Schema
  import Ecto.Changeset

  schema "bot_files" do
    belongs_to :bot, YourBot.Bots.Bot
    field :uuid, :binary_id, null: false
    field :name, :string, null: false
    field :code, :string, virtual: true
    timestamps()
  end

  def changeset(file, attrs \\ %{}) do
    file
    |> cast(attrs, [:name, :code])
    |> validate_required([:name])
  end
end
