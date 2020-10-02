defmodule ServerWeb.Router do
  use ServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ServerWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/stock", StockLive
    live "/note", NoteLive
    live "/gallery", GalleryLive
    live "/photo", PhotoLive
    live "/algorithm", AlgorithmLive
    live "/git", GitLive

    live "/tetris", TetrisLive.Welcome, :welcome
    live "/tetris/playing", TetrisLive.Playing, :playing
    live "/tetris/over", TetrisLive.GameOver, :game_over

    live "/game", GameLive.Welcome, :welcome
    live "/game/playing", GameLive.Playing, :playing
    live "/game/over", GameLive.GameOver, :game_over
  end

  # Other scopes may use custom stacks.
  # scope "/api", ServerWeb do
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
      live_dashboard "/dashboard", metrics: ServerWeb.Telemetry
    end
  end
end
