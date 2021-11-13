import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :yourbot, YourBot.Repo,
  username: "postgres",
  password: "postgres",
  database: "yourbot_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :yourbot, YourBotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QWYS0koIqOaVHh5OLJq3JVG2nkUV1XoKrgt0zjSBpYECBxwAG6Om5KQjhYRuZoCE",
  server: false

# In test we don't send emails.
config :yourbot, YourBot.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :wallaby, otp_app: :yourbot

config :yourbot, YourBotWeb.Endpoint, server: true

config :yourbot, :sandbox, Ecto.Adapters.SQL.Sandbox

config :ex_aws,
  access_key_id: ["username", :instance_role],
  secret_access_key: ["password123", :instance_role]

config :ex_aws, :s3, %{
  access_key_id: "username",
  secret_access_key: "password123",
  scheme: "http://",
  host: "localhost",
  port: 9000,
  region: "local",
  bucket: "uploads"
}

config :yourbot, YourBot.Accounts.APIToken,
  secret: "sbAuPxKKmcLw3Z0hdLDaOYo2T1LbvKJqReGai+Acl0qQn+ezKvmFtIsg/tSGqR+J"
