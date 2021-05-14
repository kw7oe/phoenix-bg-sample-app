defmodule SampleWeb.HealthController do
  use SampleWeb, :controller

  def index(conn, _params) do
    {:ok, vsn} = :application.get_key(:sample, :vsn)
    json(conn, %{healthy: true, version: to_string(vsn)})
  end
end
