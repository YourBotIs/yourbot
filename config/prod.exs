import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

# keyfile =
#   System.get_env("SSL_KEY_PATH") ||
#     raise """
#     SSL_KEY_PATH must be set
#     """

# certfile =
#   System.get_env("SSL_CERT_PATH") ||
#     raise """
#     SSL_CERT_PATH must be set
#     """

config :yourbot, YourBotWeb.Endpoint,
  url: [scheme: "https", host: "api.yourbotis.live", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  # force_ssl: [hsts: true],
  secret_key_base: secret_key_base,
  server: true,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000")
  ]

# Do not print debug messages in production
config :logger, level: :info

aws_access_key_id =
  System.get_env("AWS_ACCESS_KEY_ID") ||
    raise """
    AWS_ACCESS_KEY_ID must be set
    """

aws_secret_access_key =
  System.get_env("AWS_SECRET_ACCESS_KEY") ||
    raise """
    AWS_SECRET_ACCESS_KEY must be set
    """

config :ex_aws,
  s3: [
    scheme: "https://",
    region: "New Jersey",
    host: "ewr1.vultrobjects.com"
  ]

config :ex_aws,
  access_key_id: [aws_access_key_id, :instance_role],
  secret_access_key: [aws_secret_access_key, :instance_role]

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :yourbot, YourBot.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :yourbot, YourBot.BotSandbox, node_name: "yourbotis", chroot: "/var/chroot"

api_token_secret =
  System.get_env("API_TOKEN_SECRET") ||
    raise """
    environment variable API_TOKEN_SECRET is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :yourbot, YourBot.Accounts.APIToken, secret: api_token_secret
