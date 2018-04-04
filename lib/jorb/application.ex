defmodule Jorb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = fetchers_per_queue()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jorb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def fetchers_per_queue do
    import Supervisor.Spec, warn: false

    Enum.map(jobs_modules(), fn mod ->
      queue_name = apply(mod, :queue_name, []) |> Jorb.Backend.prefix_queue_name()

      Supervisor.child_spec({Jorb.Fetcher, queue_name}, id: queue_name)
    end)
  end

  def jobs_modules do
    {:ok, all_modules} =
      Application.get_env(:jorb, :application)
      |> :application.get_key(:modules)

    Enum.filter(all_modules, fn mod ->
      mod
      |> Atom.to_string()
      |> String.starts_with?(Application.get_env(:jorb, :namespace))
    end)
  end
end
