defmodule TelecoreWeb.PageController do
  use TelecoreWeb, :controller

  def home(conn, _params), do: redirect(conn, to: ~p"/routers")
end
