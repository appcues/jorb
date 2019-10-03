defmodule Jorb.Fetcher do
  @moduledoc ~S"""
  Jorb.Fetcher

  Fetch a batch of messages from the given queue on a timer
  """
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def poll_queue(opts) do
    poll_timeout =
      opts[:fetch_interval] ||
        Application.get_env(:jorb, :fetch_interval, 1000)

    Process.send_after(self(), :poll_queue, poll_timeout)
  end

  @impl true
  def init(opts) do
    poll_queue(opts)
    {:ok, opts}
  end

  @impl true
  def handle_info(:poll_queue, opts) do
    poll_queue()
    opts[:module].fetch_and_perform(opts)
    {:noreply, queue_name}
  end
end
