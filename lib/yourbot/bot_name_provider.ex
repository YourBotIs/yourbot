defmodule YourBot.BotNameProvider do
  alias YourBot.Bots.Bot

  def via(%Bot{id: bot_id}, module) do
    via(bot_id, module)
  end

  def via(bot_id, module) do
    {:via, Registry, {__MODULE__, "#{bot_id}", module}}
  end
end
