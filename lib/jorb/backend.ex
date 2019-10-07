defmodule Jorb.Backend do
  @moduledoc ~S"""
  The backend behavior represents a queueing abstraction.

  Enqueue pushes a message on to the queue
  Dequeue pulls the next message from the queue
  Finalize removes the given message from the queue
  """
  @type queue :: String.t()
  @type message :: map
  @type opts :: Keyword.t()

  @callback create_queue(queue, opts) :: :ok | {:error, any}
  @callback delete_queue(queue, opts) :: :ok | {:error, any}
  @callback purge_queue(queue, opts) :: :ok | {:error, any}
  @callback enqueue_message(queue, message, opts) :: :ok | {:error, any}
  @callback read_messages(queue, opts) :: {:ok, [message]} | {:error, any}
  @callback delete_message(queue, message, opts) :: :ok | {:error, any}

  @optional_callbacks [create_queue: 2, delete_queue: 2, purge_queue: 2]
end
