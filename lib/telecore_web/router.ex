defmodule TelecoreWeb.Router do
  use TelecoreWeb, :router

  import TelecoreWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TelecoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", TelecoreWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  scope "/", TelecoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", PageController, :home
    delete "/logout", SessionController, :delete

    live_session :authenticated, on_mount: {TelecoreWeb.Auth, :ensure_authenticated} do
      live "/routers", RouterLive.Index, :index
      live "/routers/new", RouterLive.Index, :new
      live "/routers/:id", RouterLive.Show, :show
      live "/routers/:id/edit", RouterLive.Show, :edit
      live "/routers/:id/sessions", SessionLive.Index, :index
      live "/routers/:id/secrets", SecretLive.Index, :index
      live "/routers/:id/secrets/new", SecretLive.Index, :new
      live "/routers/:id/secrets/:name/edit", SecretLive.Index, :edit
    end
  end

  if Application.compile_env(:telecore, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TelecoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
