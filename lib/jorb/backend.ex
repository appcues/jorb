defmodule Jorb.Backend do
  @moduledoc ~S"""
  The backend behavior represents a queueing abstraction.

  Enqueue pushes a message on to the queue
  Dequeue pulls the next message from the queue
  Finalize removes the given message from the queue
  """
  @type queue_name :: String.t()

  @callback enqueue(queue_name, map()) :: {:ok, map()} | {:error, any}
  @callback pull(queue_name) :: {:ok, [map()]} | {:error, any}
  @callback finalize(queue_name, map()) :: :ok | {:error, any}
  @callback purge(queue_name) :: :ok | {:error, any}
end
