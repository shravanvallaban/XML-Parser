defmodule XmlParser.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      XmlParserWeb.Telemetry,
      XmlParser.Repo,
      {DNSCluster, query: Application.get_env(:xml_parser, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: XmlParser.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: XmlParser.Finch},
      # Start a worker by calling: XmlParser.Worker.start_link(arg)
      # {XmlParser.Worker, arg},
      # Start to serve requests, typically the last entry
      XmlParserWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XmlParser.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    XmlParserWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
