defmodule XmlParserWeb do

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
  
  def controller do
    quote do
      use Phoenix.Controller, namespace: XmlParserWeb

      import Plug.Conn
      import XmlParserWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/xml_parser_web/templates",
        namespace: XmlParserWeb

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import XmlParserWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import XmlParserWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: XmlParserWeb.Endpoint,
        router: XmlParserWeb.Router,
        statics: XmlParserWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
