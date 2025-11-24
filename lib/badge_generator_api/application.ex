defmodule BadgeGeneratorApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BadgeGeneratorApiWeb.Telemetry,
      BadgeGeneratorApi.Repo,
      {DNSCluster, query: Application.get_env(:badge_generator_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BadgeGeneratorApi.PubSub},
      # Start a worker by calling: BadgeGeneratorApi.Worker.start_link(arg)
      # {BadgeGeneratorApi.Worker, arg},
      # Start to serve requests, typically the last entry
      BadgeGeneratorApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BadgeGeneratorApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BadgeGeneratorApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
