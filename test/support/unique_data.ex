defmodule YourBot.UniqueData do
  def unique_name(sub) do
    sub <> "-#{unique_id()}"
  end

  def unique_email(sub) do
    "#{sub}#{unique_id()}@example.com"
  end

  def unique_id do
    System.unique_integer([:positive])
  end
end
