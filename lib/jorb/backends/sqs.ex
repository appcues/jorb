defmodule Jorb.Backends.SQS do
  @behaviour Jorb.Backend
  alias ExAws.SQS

  def enqueue(queue_name, payload) do
    SQS.send_message(queue_name, Poison.encode!(payload)) |> ExAws.request()
  end

  def dequeue(queue_name) do
    %{body: %{messages: messages}} =
      SQS.receive_message(queue_name, max_number_of_messages: 10)
      |> ExAws.request!()

    messages
  end

  def finalize(queue_name, message) do
    SQS.delete_message(queue_name, message[:receipt_handle]) |> ExAws.request()
  end
end
