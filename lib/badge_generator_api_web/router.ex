defmodule BadgeGeneratorApiWeb.Router do
  use BadgeGeneratorApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BadgeGeneratorApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # protected API pipeline requiring API key authentication
  pipeline :api_protected do
    plug BadgeGeneratorApiWeb.Plugs.ApiKeyAuth
  end

  scope "/", BadgeGeneratorApiWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", BadgeGeneratorApiWeb do
    pipe_through :api

    # public endpoints
    scope "/business" do
      post "/register", BusinessController, :register
    end

    # protected endpoints (require api key)
    scope "/business" do
      pipe_through [:api_protected]
      get "/me", BusinessController, :me
    end

    # project endpoints
    scope "/projects" do
      pipe_through [:api_protected]
      get "/", ProjectController, :list
      post "/", ProjectController, :create
      get "/:id", ProjectController, :show
      put "/:id", ProjectController, :update
      delete "/:id", ProjectController, :delete
    end
  end

  # scope "/api", BadgeGeneratorApiWeb do
  #   pipe_through [:api, BadgeGeneratorApiWeb.Plugs.ApiKeyAuth]

  #   get "/badges", BadgeController, :index
  #   post "/badges/award", BadgeController, :award
  # end

  # Other scopes may use custom stacks.
  # scope "/api", BadgeGeneratorApiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:badge_generator_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BadgeGeneratorApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
