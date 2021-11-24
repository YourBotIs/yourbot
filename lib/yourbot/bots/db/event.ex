defmodule YourBot.Bots.DB.Event do
  use Ecto.Schema

  schema "yourbot_event_log" do
    field :name, :string
    field :content, :string
    timestamps()
  end
end
