defmodule GitColors.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GitColorsWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:git_colors, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GitColors.PubSub},
      # Start the CommitAnalyzer GenServer
      GitColors.CommitAnalyzer,
      # Start a worker by calling: GitColors.Worker.start_link(arg)
      # {GitColors.Worker, arg},
      # Start to serve requests, typically the last entry
      GitColorsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GitColors.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GitColorsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
