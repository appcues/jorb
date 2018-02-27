defmodule Jorb.Fetcher do
  require Logger
  use GenServer
  alias ExAws.SQS

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, queue_name)
  end

  def poll_queue() do
    poll_timeout = Application.get_env(:jorb, :fetching_timer) || 1000
    Process.send_after(self(), :poll_queue, poll_timeout)
  end

  def init(queue_name) do
    poll_queue()
    {:ok, queue_name}
  end

  def handle_info(:poll_queue, queue_name) do
    poll_queue()

    1..Application.get_env(:jorb, :fetching_processes)
    |> Enum.each(fn _ ->
      spawn(fn ->
        Jorb.backend().dequeue(queue_name)
        |> Jorb.Broker.process_batch()
      end)
    end)

    {:noreply, queue_name}
  end
end
