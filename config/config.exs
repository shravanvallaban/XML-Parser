# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config
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


config :xml_parser,
  ecto_repos: [XmlParser.Repo],
  generators: [timestamp_type: :utc_datetime]

database_url = fn ->
  username = System.get_env("POSTGRES_USERNAME") || "postgres"
  password = System.get_env("POSTGRES_PASSWORD") || "postgresuserpassword"
  host = System.get_env("POSTGRES_HOST") || "localhost"
  database = System.get_env("POSTGRES_DB") || "xml_parser_dev"
  port = System.get_env("POSTGRES_PORT") || "5432"

  "postgresql://#{username}:#{password}@#{host}:#{port}/#{database}"
end


config :xml_parser, XmlParser.Repo,
  url: database_url.(),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configures the endpoint
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
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :xml_parser, XmlParser.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
