# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :yourbot,
  namespace: YourBot,
  ecto_repos: [YourBot.Repo]

# Configures the endpoint
config :yourbot, YourBotWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: YourBotWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: YourBot.PubSub,
  live_view: [signing_salt: "dSqTVT6t"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :yourbot, YourBot.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --loader:.ttf=file --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* editor.worker=monaco-editor/esm/vs/editor/editor.worker.js ts.worker=monaco-editor/esm/vs/language/typescript/ts.worker lua=monaco-editor/esm/vs/basic-languages/lua/lua.js python=monaco-editor/esm/vs/basic-languages/python/python.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :surface, :components, [
  {Surface.Components.Form.ErrorTag,
   default_translator: {YourBotWeb.ErrorHelpers, :translate_error}}
]

config :yourbot, YourBot.BotSandbox, node_name: "127.0.0.1"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
