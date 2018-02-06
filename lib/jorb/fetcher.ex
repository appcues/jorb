defmodule Jorb.Fetcher do
  use GenServer
  alias ExAws.SQS

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, queue_name)
  end

  def poll_sqs() do
    poll_timeout = Application.get_env(:jorb, :fetching_timer) || 1000
    Process.send_after(__MODULE__, :poll_sqs, poll_timeout)
  end

  def init(queue_name) do
    poll_sqs()
    {:ok, queue_name}
  end

  def handle_info(:poll_sqs, queue_name) do
    poll_sqs()

    1..Application.get_env(:jorb, :fetching_processes)
    |> Enum.each(fn(_) ->

      %{body: %{messages: messages}} = SQS.receive_message(queue_name, max_number_of_messages: 10)
                                       |> ExAws.request!()

      Jorb.Broker.process_batch(messages)
    end)

    {:noreply, queue_name}
  end
end
