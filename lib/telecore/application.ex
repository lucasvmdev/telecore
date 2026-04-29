defmodule Telecore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Telecore.Vault,
        TelecoreWeb.Telemetry,
        Telecore.Repo,
        {DNSCluster, query: Application.get_env(:telecore, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Telecore.PubSub}
      ] ++ fake_mikrotik() ++ [TelecoreWeb.Endpoint]

    opts = [strategy: :one_for_one, name: Telecore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp fake_mikrotik do
    if Application.get_env(:telecore, :mikrotik_adapter) == Telecore.Mikrotik.Fake do
      [Telecore.Mikrotik.Fake]
    else
      []
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TelecoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
