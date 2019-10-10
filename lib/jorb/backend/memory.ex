defmodule Jorb.Backend.Memory do
  @moduledoc ~S"""
  A memory-backed backend for Jorb. Suitable for testing.
  """

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  use GenServer

  @impl GenServer
  def init(_opts) do
    {:ok, %{queues: %{}}}
  end

  @impl GenServer
  def handle_call({:create_queue, queue, _opts}, _from, state) do
    queues = state.queues |> Map.put(queue, [])
    {:reply, :ok, %{state | queues: queues}}
  end

  def handle_call({:delete_queue, queue, _opts}, _from, state) do
    queues = state.queues |> Map.delete(queue)
    {:reply, :ok, %{state | queues: queues}}
  end

  def handle_call({:purge_queue, queue, _opts}, _from, state) do
    queues = state.queues |> Map.put(queue, [])
    {:reply, :ok, %{state | queues: queues}}
  end

  def handle_call({:write_messages, queue, messages, _opts}, _from, state) do
    old_messages = state.queues[queue] || []
    queues = state.queues |> Map.put(queue, old_messages ++ messages)
    {:reply, :ok, %{state | queues: queues}}
  end

  def handle_call({:read_messages, queue, opts}, _from, state) do
    read_batch_size = opts[:read_batch_size] || 1
    batch = Enum.take(state.queues[queue], read_batch_size)

    # we don't delete from the queue here; imagine a visibility_timeout of 0
    {:reply, {:ok, batch}, state}
  end

  def handle_call({:delete_message, queue, message, _opts}, _from, state) do
    messages = state.queues[queue] |> Enum.filter(&(&1 != message))
    queues = state.queues |> Map.put(queue, messages)
    {:reply, :ok, %{state | queues: queues}}
  end

  @behaviour Jorb.Backend

  @impl Jorb.Backend
  def create_queue(queue, opts) do
    GenServer.call(__MODULE__, {:create_queue, queue, opts})
  end

  @impl Jorb.Backend
  def delete_queue(queue, opts) do
    GenServer.call(__MODULE__, {:delete_queue, queue, opts})
  end

  @impl Jorb.Backend
  def purge_queue(queue, opts) do
    GenServer.call(__MODULE__, {:purge_queue, queue, opts})
  end

  @impl Jorb.Backend
  def write_messages(queue, messages, opts) do
    GenServer.call(__MODULE__, {:write_messages, queue, messages, opts})
  end

  @impl Jorb.Backend
  def read_messages(queue, opts) do
    GenServer.call(__MODULE__, {:read_messages, queue, opts})
  end

  @impl Jorb.Backend
  def delete_message(queue, message, opts) do
    GenServer.call(__MODULE__, {:delete_message, queue, message, opts})
  end
end
