defmodule Jorb.Backend.SQS do
  @behaviour Jorb.Backend
  alias ExAws.SQS

  def setup(queue_name) do
    SQS.create_queue() |> ExAws.request!()
  end

  def enqueue(queue_name, payload) do
    with {:ok, encoded} <- Poison.encode(payload),
         message <- SQS.send_message(queue_name, encoded),
         {:ok, response} <- ExAws.request(message) do
      {:ok, payload}
    else
      err -> err
    end
  end

  def pull(queue_name) do
    with request <- SQS.receive_message(queue_name, max_number_of_messages: 10),
         {:ok, %{body: %{messages: messages}}} <- ExAws.request(request) do
      messages
    else
      err -> err
    end
  end

  def finalize(queue_name, message) do
    SQS.delete_message(queue_name, message[:receipt_handle]) |> ExAws.request()
  end

  def purge(queue_name) do
    with request <- SQS.purge_queue(queue_name),
         {:ok, _response} <- ExAws.request() do
      :ok
    else
      err -> err
    end
  end
end
