defmodule YourBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      YourBot.Repo,
      # Start the Telemetry supervisor
      YourBotWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: YourBot.PubSub},
      YourBot.Bots.Presence,
      YourBot.Editor.Presence,
      {Registry, keys: :unique, name: YourBot.BotNameProvider},
      YourBot.BotSupervisor,
      # Start the Endpoint (http/https)
      YourBotWeb.Endpoint,
      {SocketDrano, refs: :all},
      {Task, &populate_bot_sandboxes/0}
      # Start a worker by calling: YourBot.Worker.start_link(arg)
      # {YourBot.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YourBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YourBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def populate_bot_sandboxes do
    for bot <- YourBot.Bots.list_started_bots() do
      # YourBot.BotSupervisor.start_child(bot)
    end
  end
end
