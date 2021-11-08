defmodule YourBot.Sandbox do
  def allow(repo, owner_pid, child_pid) do
    # Delegate to the Ecto sandbox
    Ecto.Adapters.SQL.Sandbox.allow(repo, owner_pid, child_pid)
  end
end
