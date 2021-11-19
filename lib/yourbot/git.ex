defmodule YourBot.Git do
  alias YourBot.Repo
  alias YourBot.Accounts.APIToken
  alias YourBot.Bots.BotUser

  def init(%BotUser{} = bot_user) do
    %{bot: bot, user: user} = Repo.preload(bot_user, [:bot, user: [:discord_oauth]])
    token = APIToken.generate(user, :git)
    {_, 0} = System.cmd("git", ["init", "--bare", "#{bot.id}"], cd: storage_dir())
    File.mkdir_p!(Path.join([storage_dir(), "#{bot.id}", "work"]))
    url = YourBotWeb.Router.Helpers.bots_url(YourBotWeb.Endpoint, :code, bot)
    hook = EEx.eval_file(post_receive_template(), bot: bot, token: token, url: url)
    path = Path.join([storage_dir(), "#{bot.id}", "hooks", "post-receive"])
    :ok = File.write!(path, hook)
    :ok = File.chmod!(path, 0o755)
    {_, 0} = System.cmd("git", ["update-server-info"], cd: storage_dir())
    # username = "#{user.discord_oauth.username}"
    # {_, 0} = System.cmd("htpasswd", ["-b", htpasswd_file(), username, password])
    :ok
  end

  def storage_dir() do
    Application.get_env(:yourbot, __MODULE__)[:storage_dir]
  end

  def htpasswd_file() do
    Application.get_env(:yourbot, __MODULE__)[:htpasswd]
  end

  def post_receive_template do
    Application.app_dir(:yourbot, ["priv", "sandbox", "post-receive.eex"])
  end
end
