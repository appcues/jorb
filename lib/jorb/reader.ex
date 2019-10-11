defmodule Jorb.Reader do
  @moduledoc false

  use GenServer

  @impl true
  def init(opts) do
    poll_queue(opts)
    {:ok, opts}
  end

  @impl true
  def handle_info(:poll_queue, opts) do
    poll_queue(opts)
    opts[:module].work(opts)
    {:noreply, opts}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def poll_queue(opts) do
    poll_timeout = Jorb.config(:read_interval, opts, opts[:module])
    Process.send_after(self(), :poll_queue, poll_timeout)
  end
end
