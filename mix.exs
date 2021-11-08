defmodule YourBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :yourbot,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {YourBot.Application, []},
      extra_applications: [:logger, :runtime_tools, :eex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"] ++ catalogues()
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws, "~> 2.1"},
      {:excoveralls, "~> 0.10", only: :test},
      {:extty, github: "connorrigby/extty"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.2"},
      {:jose, "~> 1.11"},
      {:mime, "~> 2.0", override: true},
      {:muontrap, "~> 1.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.16.0"},
      {:phoenix, "~> 1.6.2"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:surface_bulma, "~> 0.2"},
      {:surface_catalogue, "~> 0.2.0"},
      {:surface_formatter, "~> 0.6.0"},
      {:surface, "~> 0.6.1", override: true},
      {:sweet_xml, "~> 0.6"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:wallaby, "~> 0.29.1", only: :test},
      {:x509, "~> 0.8.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end

  def catalogues do
    [
      "priv/catalogue"
    ]
  end
end
