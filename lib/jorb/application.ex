defmodule Jorb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    :ets.new(Jorb.Writer.Batches, [
      :set,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(Jorb.Backend.SQS.QueueUrls, [
      :set,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    children = [
      %{id: Jorb.Backend.Memory, start: {Jorb.Backend.Memory, :start_link, []}}
    ]
    opts = [strategy: :one_for_one, name: Jorb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
