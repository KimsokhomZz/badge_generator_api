defmodule BadgeGeneratorApiWeb.PageController do
  use BadgeGeneratorApiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
