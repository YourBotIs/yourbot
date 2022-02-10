defmodule YourBotWeb.FileView do
  use YourBotWeb, :view

  def render("index.json", %{files: files}) do
    %{
      data:
        render_many(
          files,
          YourBotWeb.FileView,
          "file.json",
          as: :file
        )
    }
  end

  def render("show.json", %{file: file}) do
    %{data: render_one(file, YourBotWeb.FileView, "file.json", as: :file)}
  end

  def render("file.json", %{file: file}) do
    %{
      id: file.id,
      name: file.name,
      content: file.content,
      uuid: file.uuid,
      inserted_at: file.inserted_at,
      updated_at: file.updated_at
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Map.new(changeset.errors, fn {name, {error, _}} -> {name, error} end)
    %{errors: errors}
  end
end
