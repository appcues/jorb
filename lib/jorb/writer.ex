defmodule Jorb.Writer do
  use GenServer
  import Jorb.Utils

  @impl GenServer
  def init(opts) do
    {:ok, %{write_interval: Jorb.config(:write_interval, opts)}}
  end

  @impl GenServer
  def handle_call(:flush, _from, state) do
    Process.send_after(self(), :flush, state.write_interval)
    {:reply, :ok, state}
  end

  @table Jorb.Writer.Batches

  @spec enqueue(Jorb.queue(), map, Keyword.t(), atom) :: :ok | {:error, String.t()}
  def enqueue(queue, message, opts, module) do
    write_batch_size = Jorb.config(:write_batch_size, opts, module)
    backend = Jorb.config(:backend, opts, module)

    if write_batch_size == 1 do
      backend.write_messages(queue, [message])
      :ok
    else
      key = get_batch_key(queue, opts, module)

      with_ets_lock(@table, key, fn
        [] ->
          :ets.insert(@table, {key, [message]})
          :ok

        [old_batch] ->
          batch = [message | old_batch]

          if Enum.count(batch) < write_batch_size do
            :ets.insert(@table, {key, batch})
            :ok
          else
            with :ok <- backend.write_messages(queue, batch),
                 true <- :ets.delete(@table, key) do
              :ok
            end
          end
      end)
    end
  end

  def flush(queue, opts, module) do
  end

  ## Returns a key that can be used to retrieve a batch of outgoing
  ## messages. Cycles through multiple writers round-robin.
  defp get_batch_key(queue, opts, module) do
    counter_key = {queue, module, :counter}

    counter =
      case :ets.lookup(@table, counter_key) do
        [c] ->
          c

        [] ->
          c = :counters.new(1)
          :ets.insert(@table, {counter_key, c})
          c
      end

    counter_value = :counters.get(counter, 1)
    :counters.add(counter, 1, 1)

    writer_count = Jorb.config(:writer_count, opts, module)
    {queue, module, rem(counter_value, writer_count)}
  end
end
