defmodule Jorb.Backend do
  @moduledoc ~S"""
  The backend behavior represents a queueing abstraction.

  Jorb requires three functions to be defined for a backend: `c:enqueue/2`, `c:dequeue/1`, and `c:finalize/2`

  Enqueue pushes a message on to the queue
  Dequeue pulls the next message from the queue
  Finalize removes the given message from the queue
  """

  @callback enqueue(String.t(), Map.t()) :: :ok | :error
  @callback dequeue(String.t()) :: [Map.t()]
  @callback finalize(String.t(), Map.t()) :: :ok | :error
end
