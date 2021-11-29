defmodule YourBot.Bots.Project.File do
  @moduledoc "Represents a single file. Folders are implicit"
  use Ecto.Schema
  import Ecto.Changeset

  schema "yourbot_files" do
    belongs_to :project, YourBot.Bots.Project
    field :uuid, :binary_id, null: false
    field :name, :string, null: false
    field :content, :string, null: false
    timestamps()
  end

  def changeset(file, attrs \\ %{}) do
    file
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
    |> validate_name()
    |> unique_constraint([:project_id, :name], message: "project filenames must be unique")
    |> put_uuid()
  end

  def put_uuid(%{valid?: false} = changeset) do
    changeset
  end

  def put_uuid(changeset) do
    if get_field(changeset, :uuid) do
      changeset
    else
      put_change(changeset, :uuid, Ecto.UUID.autogenerate())
    end
  end

  def validate_name(%{valid?: false} = chagneset) do
    chagneset
  end

  # todo: p sure ecto has a thing for this
  def validate_name(changeset) do
    if name = get_change(changeset, :name) do
      # yikes
      if Regex.match?(~r/(\s+|\/|\\|"|'|`)+/, name) do
        add_error(changeset, :name, "May not contain special characters", [:name])
      else
        changeset
      end
    else
      changeset
    end
  end
end
