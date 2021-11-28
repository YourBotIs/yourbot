defmodule YourBot.FileFixtures do
  alias YourBot.Bots.Project
  import YourBot.UniqueData

  def valid_file_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_name("file"),
      content: unique_name("content")
    })
  end

  def file_fixture(project, attrs) do
    {:ok, file} = Project.create_file(project, attrs)
    file
  end

  def setup_project_file(%{bot: %{project: project}} = env) do
    file = file_fixture(project, valid_file_attrs())
    Map.put(env, :project_file, file)
  end
end
