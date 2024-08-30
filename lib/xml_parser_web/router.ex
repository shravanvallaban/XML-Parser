defmodule XmlParserWeb.Router do
  use XmlParserWeb, :router

  # Define the API pipeline
  pipeline :api do
    plug :accepts, ["json-api"]
    plug CORSPlug, origin: ["*"]
  end

  # Define API routes
  scope "/api", XmlParserWeb.Api do
    pipe_through :api

    # Route for file upload
    post "/files", FileController, :create
    # Route for file search
    get "/files", FileController, :search
  end
end
