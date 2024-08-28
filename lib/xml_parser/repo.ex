defmodule XmlParser.Repo do
  use Ecto.Repo,
    otp_app: :xml_parser,
    adapter: Ecto.Adapters.Postgres
end
