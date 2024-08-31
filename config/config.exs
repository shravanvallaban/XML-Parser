import Config

# Load environment variables from .env file if it exists
try do
  File.stream!(".env")
  |> Stream.map(&String.trim/1)
  |> Enum.each(fn line ->
    [key, value] = String.split(line, "=")
    System.put_env(key, value)
  end)
rescue
  _ -> IO.puts("No .env file found. Using default configuration.")
end

# General application configuration
config :xml_parser,
  ecto_repos: [XmlParser.Repo],
  generators: [timestamp_type: :utc_datetime]

# Database URL configuration function
database_url = fn ->
  username = System.get_env("POSTGRES_USERNAME")
  password = System.get_env("POSTGRES_PASSWORD")
  host = System.get_env("POSTGRES_HOST")
  database = System.get_env("POSTGRES_DB")
  port = System.get_env("POSTGRES_PORT")

  "postgresql://#{username}:#{password}@#{host}:#{port}/#{database}"
end

# Database configuration
config :xml_parser, XmlParser.Repo,
  url: database_url.(),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Endpoint configuration
config :xml_parser, XmlParserWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: XmlParserWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: XmlParser.PubSub,
  live_view: [signing_salt: "TTeZXYNv"]

# Configures the mailer
config :xml_parser, XmlParser.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
