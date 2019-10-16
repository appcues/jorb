defmodule Jorb.Writer do
  @moduledoc false

  use GenServer

  @type batch_key :: {Jorb.queue(), atom, non_neg_integer}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl GenServer
  def init(opts) do
    state = %{
      write_interval: Jorb.config(:write_interval, opts),
      batch_key: opts[:batch_key],
      opts: opts
    }

    Process.send_after(self(), :flush, state.write_interval)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:flush, state) do
    flush_batch(state.batch_key, state.opts)
    Process.send_after(self(), :flush, state.write_interval)
    {:noreply, state}
  end

  @table Jorb.Writer.Batches

  @doc ~S"""
  Enqueues a message for writing to a queue, writing the batch of messages
  synchronously if at least `:write_batch_size` are present.

  If the `:writer_count` option is more than 1, a batch of messages is
  chosen round-robin.
  """
  @spec enqueue(Jorb.queue(), map, Keyword.t(), atom) :: :ok | {:error, String.t()}
  def enqueue(queue, message, opts, module) do
    write_batch_size = Jorb.config(:write_batch_size, opts, module)
    backend = Jorb.config(:backend, opts, module)

    if write_batch_size == 1 do
      backend.write_messages(queue, [message], opts)
      :ok
    else
      batch_key = get_batch_key(queue, opts, module)

      EtsLock.with_ets_lock(@table, batch_key, fn
        [] ->
          :ets.insert(@table, {batch_key, [message]})
          :ok

        [{_batch_key, old_batch}] ->
          batch = [message | old_batch]

          if Enum.count(batch) < write_batch_size do
            :ets.insert(@table, {batch_key, batch})
            :ok
          else
            with :ok <- backend.write_messages(queue, batch, opts),
                 true <- :ets.delete(@table, batch_key) do
              :ok
            end
          end
      end)
    end
  end

  @doc ~S"""
  Flushes a given batch, deleting it from the table on success.
  """
  def flush_batch({queue, module, _n} = batch_key, opts) do
    backend = Jorb.config(:backend, opts, module)

    EtsLock.with_ets_lock(@table, batch_key, fn
      [] ->
        :ok

      [{_batch_key, batch}] ->
        with :ok <- backend.write_messages(queue, batch, opts),
             true <- :ets.delete(@table, batch_key) do
          :ok
        end
    end)
  end

  @doc ~S"""
  Returns a key that can be used to retrieve a batch of outgoing
  messages. If :writer_count is set above 1, get_batch_key cycles
  through batches round-robin.
  """
  @spec get_batch_key(Jorb.queue(), Keyword.t(), atom) :: batch_key
  def get_batch_key(queue, opts, module) do
    counter_key = {queue, module, :counter}

    counter =
      case :ets.lookup(@table, counter_key) do
        [{_counter_key, c}] ->
          c

        [] ->
          c = :counters.new(1, [:atomics])
          :ets.insert(@table, {counter_key, c})
          c
      end

    counter_value = :counters.get(counter, 1)
    :counters.add(counter, 1, 1)

    writer_count = Jorb.config(:writer_count, opts, module)
    {queue, module, 1 + rem(counter_value, writer_count)}
  end
end
