defmodule YourBotWeb.Router do
  use YourBotWeb, :router

  import Surface.Catalogue.Router

  import YourBotWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {YourBotWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", YourBotWeb do
    pipe_through [:api, :require_authenticated_api_token]
    resources "/users", UsersController, only: [:create, :show, :update, :delete]
    resources "/bots", BotsController, only: [:index, :create, :show, :update, :delete]
  end

  scope "/", YourBotWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/demo", Demo
  end

  # Other scopes may use custom stacks.
  # scope "/api", YourBotWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: YourBotWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", YourBotWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
  end

  scope "/", YourBotWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/bots", BotLive, :index
  end

  scope "/", YourBotWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
    get "/oauth/discord", DiscordOAuthController, :oauth
  end

  if Mix.env() == :dev do
    scope "/" do
      pipe_through :browser
      surface_catalogue("/catalogue")
    end
  end
end
