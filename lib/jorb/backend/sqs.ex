defmodule Jorb.Backend.SQS do
  @behaviour Jorb.Backend
  alias ExAws.SQS

  @impl true
  def create_queue(queue, opts) do
    request = SQS.create_queue(queue, opts)

    case ExAws.request(request) do
      {:ok, %{body: %{queue_url: queue_url}}} ->
        put_queue_url(queue, queue_url)
        :ok

      err ->
        err
    end
  end

  defp get_queue_url(queue) do
    case :ets.lookup(Jorb.Backend.SQS.QueueUrls, queue) do
      [{_queue, queue_url}] ->
        {:ok, queue_url}

      [] ->
        request = SQS.get_queue_url(queue)

        with {:ok, %{body: %{queue_url: queue_url}}} <- ExAws.request(request) do
          put_queue_url(queue, queue_url)
          {:ok, queue_url}
        end
    end
  end

  defp put_queue_url(queue, queue_url) do
    :ets.insert(Jorb.Backend.SQS.QueueUrls, {queue, queue_url})
  end

  @impl true
  def delete_queue(queue, _opts) do
    with {:ok, queue_url} <- get_queue_url(queue),
         request <- SQS.delete_queue(queue_url),
         {:ok, _} <- ExAws.request(request) do
      :ok
    end
  end

  @impl true
  def purge_queue(queue, _opts) do
    with {:ok, queue_url} <- get_queue_url(queue),
         request <- SQS.purge_queue(queue_url),
         {:ok, _} <- ExAws.request(request) do
      :ok
    end
  end

  @impl true
  def write_messages(queue, messages, _opts) do
    with {:ok, encoded_messages} <- encode_messages(messages, []),
         {:ok, queue_url} <- get_queue_url(queue),
         request <- SQS.send_message_batch(queue_url, encoded_messages),
         {:ok, _response} <- ExAws.request(request) do
      :ok
    else
      err -> err
    end
  end

  defp encode_messages([], encoded), do: {:ok, encoded}

  defp encode_messages([message | rest], encoded) do
    with {:ok, body} <- Poison.encode(message) do
      id = UUID.uuid4()

      ## we need to encode this as a keyword list -- the ExAws.SQS docs lie
      encoded_message = [
        id: id,
        message_body: body,
        message_attributes: []
      ]

      encode_messages(rest, [encoded_message | encoded])
    end
  end

  @impl true
  def read_messages(queue, opts) do
    read_batch_size = opts[:read_batch_size]
    read_duration = opts[:read_duration]
    read_timeout = opts[:read_timeout]

    with {:ok, queue_url} <- get_queue_url(queue),
         request <-
           SQS.receive_message(queue_url,
             wait_time_seconds: round(read_duration / 1000),
             max_number_of_messages: read_batch_size
           ) do
      request_task = Task.async(fn -> ExAws.request(request) end)

      case Task.yield(request_task, read_timeout) do
        nil ->
          Task.shutdown(request_task)
          {:error, "pull error: read timeout"}

        {:exit, reason} ->
          {:error, "pull error: #{inspect(reason)}"}

        {:ok, {:error, e}} ->
          {:error, inspect(e)}

        {:ok, {:ok, %{body: %{messages: messages}}}} ->
          {:ok, messages}
      end
    end
  end

  @impl true
  def delete_message(queue, message, _opts) do
    with {:ok, queue_url} <- get_queue_url(queue),
         request <- SQS.delete_message(queue_url, message[:receipt_handle]),
         {:ok, _} <- ExAws.request(request) do
      :ok
    end
  end
end
