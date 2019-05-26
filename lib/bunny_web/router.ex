defmodule BunnyWeb.Router do
  use BunnyWeb, :router


  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BunnyWeb do
    pipe_through :api

    post "/", TaskController, :sort
    post "/sh", TaskController, :shell
  end
end
