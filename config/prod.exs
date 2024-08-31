import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: XmlParser.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
# Do not print debug messages in production
config :logger, level: :info

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

  # Configure secret key base for signing tokens
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :xml_parser, XmlParserWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base
