defmodule Jorb.Worker do
  @moduledoc ~S"""
  Read from queues and perform jobs.
  """
  require Logger
  use GenServer

  @impl true
  def init(opts) do
    poll_queue(opts)
    {:ok, opts}
  end

  @impl true
  def handle_info(:poll_queue, opts) do
    poll_queue(opts)
    opts[:module].fetch_and_perform(opts)
    {:noreply, opts}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def poll_queue(opts) do
    poll_timeout =
      opts[:fetch_interval] ||
        Application.get_env(:jorb, :fetch_interval, 1000)

    Process.send_after(self(), :poll_queue, poll_timeout)
  end
end
