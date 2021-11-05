defmodule YourBot.BotSupervisor do
  use DynamicSupervisor

  alias YourBot.Bots.Bot
  alias YourBot.BotSandbox

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(%Bot{} = bot) do
    DynamicSupervisor.start_child(__MODULE__, {BotSandbox, bot})
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
