import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :xml_parser, XmlParser.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "xml_parser_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :xml_parser, XmlParserWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Yg/dIEkw9ki3ihcKgwr6Kvy315mwEuVi+lTkQwQaHTVSVytUiOqiXInr6buy3roG",
  server: false

# In test we don't send emails
config :xml_parser, XmlParser.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
