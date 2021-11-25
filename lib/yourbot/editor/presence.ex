defmodule YourBot.Editor.Presence do
  use Phoenix.Presence,
    otp_app: :yourbot,
    pubsub_server: YourBot.PubSub
end
