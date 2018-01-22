defmodule Jorb.Fetcher do
  use GenServer
  alias ExAws.SQS

  def start_link(queue_name) do
    name = via(queue_name)
    GenServer.start_link(__MODULE__, queue_name, name: name)
  end

  def poll_sqs(queue_name) do
    poll_timeout = Application.get_env(:jorb, :fetching_timer)
    Process.send_after(via(queue_name), :poll_sqs, poll_timeout)
  end

  def init(queue_name) do
    poll_sqs(queue_name)
    {:ok, queue_name}
  end

  def via(queue_name) do
    {:via, Registry, {:fetcher_registry, queue_name}}
  end

  def handle_info(:poll_sqs, queue_name) do
    poll_sqs(queue_name)

    response = SQS.receive_message(queue_name, max_number_of_messages: 10) |> ExAws.request!()
    %{body: %{messages: messages}} = response

    Jorb.Broker.process_batch(messages)

    {:noreply, queue_name}
  end
end
