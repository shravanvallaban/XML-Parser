import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :xml_parser, XmlParser.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is generated in config/prod.exs
  config :xml_parser, XmlParserWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      ip: {0, 0, 0, 0, 0, 0, 0, 0}  # This replaces the inet6 socket option
    ]
end
