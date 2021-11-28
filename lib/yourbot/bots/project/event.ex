defmodule YourBot.Bots.Project.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "yourbot_event_log" do
    belongs_to :project, YourBot.Bots.Project
    field :name, :string
    field :content, :string
    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
  end
end
