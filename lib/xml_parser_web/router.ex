defmodule XmlParserWeb.Router do
  use XmlParserWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["*"]
  end

  scope "/api", XmlParserWeb.Api do
    pipe_through :api

    post "/files", FileController, :create
    get "/files/search", FileController, :search
  end
end
