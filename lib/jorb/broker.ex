defmodule Jorb.Broker do

  require Logger
  use GenServer
  alias ExAws.SQS

  ## Contract
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def process_batch(messages) do
    GenServer.cast(__MODULE__, {:process_batch, messages})
  end

  ## Callbacks

  # State is irrelevant
  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:process_batch, messages}, state) do
    Enum.each(messages, fn(message) ->
      # Spawn a process to handle each message. Failures are totally tolerable,
      # since the message will be re-queued if we fail anywhere along the way
      spawn fn ->
        # rehydrate the message's body (the payload) then hand it to the process method
        # the payload is a map of %{ via: <module name>, body: %{ <actual params> } }
        %{ "target" => module_name, "body" => payload } = Poison.decode!(message.body)
        target = String.to_existing_atom(module_name)
        queue_name = apply(target, :queue_name, [])

        apply(target, :perform, [payload])

        # finally, delete the message
        SQS.delete_message(queue_name, message[:receipt_handle]) |> ExAws.request!
      end
    end)

    {:noreply, state}
  end
end
