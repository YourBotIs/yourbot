defmodule YourBot.BotSupervisor do
  use DynamicSupervisor

  alias YourBot.Bots.Bot
  alias YourBot.BotSandbox
  import YourBot.BotNameProvider, only: [via: 2]

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(%Bot{} = bot) do
    DynamicSupervisor.start_child(__MODULE__, {BotSandbox, bot})
  end

  def lookup_child(%Bot{} = bot) do
    GenServer.whereis(via(bot, BotSandbox))
  end

  def terminate_child(%Bot{} = bot) do
    if pid = lookup_child(bot) do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
