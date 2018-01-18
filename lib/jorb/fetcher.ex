defmodule Jorb.Fetcher do
  use GenServer
  alias ExAws.SQS

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, queue_name)
  end

  def poll_sqs() do
    Process.send_after(self(), :poll_sqs, 5000)
  end

  def init(queue_name) do
    poll_sqs()
    {:ok, queue_name }
  end

  def handle_info(:poll_sqs, queue_name) do
    poll_sqs()

    response = SQS.receive_message(queue_name, max_number_of_messages: 10) |> ExAws.request!
    %{body: %{messages: messages}} = response

    Jorb.Broker.process_batch(messages)

    {:noreply, queue_name }
  end

  def child_spec(args) do
    # It is definitely dangerous to define atoms all willy-nilly like this, since they
    # will never be GC'd, but we start a finite amount of these processes and they hang around
    %{
      id: String.to_atom("#{__MODULE__}-#{:rand.uniform(10_000)}"),
      start: { __MODULE__, :start_link, [args]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end
end
