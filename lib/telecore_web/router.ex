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
