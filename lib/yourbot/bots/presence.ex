defmodule YourBot.Bots.Presence do
  @moduledoc """
  Implementation of Phoenix.Presence for Devices connected to NervesHub.

  # Example Usage

  ## List all running bots

      iex> YourBot.Bots.Presence.list("bots")

  ## Get a particular device's presence
      iex> bot = %YourBot.Bots.Bot{...}
      iex> YourBot.Bots.Presence.find(bot)
  """

  use Phoenix.Presence,
    otp_app: :yourbot,
    pubsub_server: YourBot.PubSub

  alias YourBot.Bots.Presence
  alias YourBot.Bots.Bot

  @allowed_fields [
    :started_at
  ]

  @typedoc """
  Status of the current connection.
  Human readable string, should not be used
  pragmatically
  """
  @type status :: String.t()

  @type bot_id_string :: String.t()

  @type bot_presence :: %{}

  @type presence_list :: %{optional(bot_id_string) => bot_presence}

  # because of how the `use` statement defines this function
  # and how the elaborate callback system works for presence,
  # this spec is not accepted by dialyzer, however when
  # one calls `list(product:#{product_id}:devices)` it will
  # return the `presence_list` value
  # @spec list(String.t()) :: presence_list()

  def fetch("bots", entries) do
    for {key, entry} <- entries, into: %{}, do: {key, merge_metas(entry)}
  end

  def fetch(_, entries), do: entries

  def find(bot, default \\ nil)

  def find(%Bot{id: bot_id}, default) do
    Presence.list("bots")
    |> Map.get("#{bot_id}", default)
  end

  def find(_, default), do: default

  def into_meta(meta) do
    Map.take(meta, @allowed_fields)
  end

  defp merge_metas(%{metas: metas}) do
    # The most current meta is head of the list so we
    # accumulate that first and merge everthing else into it
    Enum.reduce(metas, %{}, &Map.merge(&1, &2))
    |> Map.take(@allowed_fields)
  end

  defp merge_metas(unknown), do: unknown
end
