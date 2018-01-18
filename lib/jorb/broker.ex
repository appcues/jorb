defmodule Jorb.Broker do
  @moduledoc ~S"""
  Jorb.Broker

  Takes a batch of messages, decodes them, sends them off to their target, then deletes them.
  """
  use GenServer
  use Elixometer
  alias ExAws.SQS

  ## Contract
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc ~S"""
  Process a batch of messages asynchronously. Called by `Jorb.Fetcher`.

  The body of the SQS message will contain a "target" key whose value is the module
  that will have its' `perform` function called. Funny enough, it's the same module
  that called `perform_async` provided by `Jorb.Job`.

  A batch of messages is however many SQS hands us back in one request, so, up to 10.

  It's fine that we don't ask for acknowledgement here, since we're completely tolerant of failures.
  If a message (or batch, even) gets dropped, they'll be requeued once their visibility timeout
  passes.
  """
  def process_batch(messages) do
    GenServer.cast(__MODULE__, {:process_batch, messages})
  end

  ## Callbacks

  # State is irrelevant
  def init(:ok) do
    {:ok, :ignored}
  end

  def handle_cast({:process_batch, messages}, state) do
    Enum.each(messages, fn(message) ->
      # Spawn a process to handle each message. Failures are totally tolerable,
      # since the message will be re-queued if we fail anywhere along the way
      spawn fn ->
        # rehydrate the message's body (the payload) then hand it to the process method
        # the payload is a map of %{ "target" => <module name>, "body" => %{ <actual params> } }
        %{ "target" => module_name, "body" => payload } = Poison.decode!(message.body)
        target = String.to_existing_atom(module_name)
        queue_name = apply(target, :queue_name, [])

        apply(target, :perform, [payload])

        # finally, delete the message
        SQS.delete_message(queue_name, message[:receipt_handle]) |> ExAws.request!

        update_counter("jorb.sqs.messages", -1)
      end
    end)

    {:noreply, state}
  end
end
