defmodule Jorb.Fetcher do
  @moduledoc ~S"""
  Jorb.Fetcher

  Fetch a batch of messages from the given queue on a timer
  """
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
    Jorb.backend().setup(queue_name)
    poll_queue()
    {:ok, queue_name}
  end

  def handle_info(:poll_queue, queue_name) do
    poll_queue()

    1..Application.get_env(:jorb, :fetching_processes)
    |> Enum.each(fn _ ->
      spawn(fn ->
        # TODO: currently we don't do anything with this error
        # but we should probably provide a callback or something
        # so consumers of Jorb can like report to sentry or something
        case Jorb.backend().dequeue(queue_name) do
          {:ok, messages} -> Jorb.Broker.process_batch()
          {:error, err} -> raise err
        end
      end)
    end)

    {:noreply, queue_name}
  end
end
