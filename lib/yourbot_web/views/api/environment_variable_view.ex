defmodule YourBotWeb.EnvironmentVariableView do
  use YourBotWeb, :view

  def render("index.json", %{environment_variables: environment_variables}) do
    %{
      data:
        render_many(
          environment_variables,
          YourBotWeb.EnvironmentVariableView,
          "environment_variable.json",
          as: :environment_variable
        )
    }
  end

  def render("show.json", %{environment_variable: environment_variable}) do
    %{
      data:
        render_one(
          environment_variable,
          YourBotWeb.EnvironmentVariableView,
          "environment_variable.json",
          as: :environment_variable
        )
    }
  end

  def render("environment_variable.json", %{environment_variable: environment_variable}) do
    %{
      id: environment_variable.id,
      key: environment_variable.key,
      value: environment_variable.value,
      inserted_at: environment_variable.inserted_at,
      updated_at: environment_variable.updated_at
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Map.new(changeset.errors, fn {name, {error, _}} -> {name, error} end)
    %{errors: errors}
  end
end
