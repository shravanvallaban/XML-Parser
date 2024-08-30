defmodule XmlParserWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :xml_parser

  # Session configuration
  @session_options [
    store: :cookie,
    key: "_xml_parser_key",
    signing_salt: "VRnmrkfx",
    same_site: "Lax"
  ]

  # Socket configuration for LiveView
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static files
  plug Plug.Static,
    at: "/",
    from: :xml_parser,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Code reloading configuration
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :xml_parser
  end

  # Request logging for LiveDashboard
  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Request parsing configuration
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # Enable CORS
  plug CORSPlug, origin: ["*"]

  plug XmlParserWeb.Router
end
