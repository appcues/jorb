defmodule Jorb.Backend.SQS do
  @behaviour Jorb.Backend
  alias ExAws.SQS

  @impl true
  def create_queue(queue, _opts) do
    request = SQS.create_queue(queue)

    case ExAws.request(request) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def delete_queue(queue, _opts) do
    request = SQS.delete_queue(queue)

    case ExAws.request(request) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def purge_queue(queue, _opts) do
    request = SQS.purge_queue(queue)

    case ExAws.request(request) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def enqueue_message(queue, payload, _opts) do
    with {:ok, encoded} <- Poison.encode(payload),
         request <- SQS.send_message(queue, encoded),
         {:ok, _response} <- ExAws.request(request) do
      :ok
    else
      err -> err
    end
  end

  @impl true
  def read_messages(queue, opts) do
    read_batch_size = opts[:read_batch_size]
    read_duration = opts[:read_duration]
    read_timeout = opts[:read_timeout]

    request =
      SQS.receive_message(queue,
        receive_message_wait_time_seconds: round(read_duration / 1000),
        max_number_of_messages: read_batch_size
      )

    request_task = Task.async(fn -> ExAws.request(request) end)

    case Task.yield(request_task, read_timeout) do
      {task, nil} ->
        Task.shutdown(task)
        {:error, "pull error: read timeout"}

      {_task, {:ok, %{body: %{messages: messages}}}} ->
        {:ok, messages}

      {_task, {:error, e}} ->
        {:error, "pull error: #{inspect(e)}"}
    end
  end

  @impl true
  def delete_message(queue, message, _opts) do
    request = SQS.delete_message(queue, message[:receipt_handle])

    case ExAws.request(request) do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
