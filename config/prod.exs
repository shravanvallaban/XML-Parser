import Config

config :xml_parser, XmlParserWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Generate a secret key base at runtime
config :xml_parser, XmlParserWeb.Endpoint,
  secret_key_base: Base.encode64(:crypto.strong_rand_bytes(48))

# Do not print debug messages in production
config :logger, level: :info

# Configure your database
config :xml_parser, XmlParser.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
