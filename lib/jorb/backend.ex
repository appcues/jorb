defmodule Jorb.Backend do
  @moduledoc ~S"""
  The backend behavior represents a queueing abstraction.

  Jorb requires four functions to be defined for a backend:
  `c:setup/1`, `c:enqueue/2`, `c:dequeue/1`, and `c:finalize/2`


  Setup handles anything to create the underlying queue
  Enqueue pushes a message on to the queue
  Dequeue pulls the next message from the queue
  Finalize removes the given message from the queue
  """

  @callback setup(String.t()) :: :ok | no_return
  @callback enqueue(String.t(), Map.t()) :: {:ok, Map.t()} | {:error, any}
  @callback dequeue(String.t()) :: [Map.t()]
  @callback finalize(String.t(), Map.t()) :: :ok | {:error, any}
  @callback purge(String.t()) :: :ok | {:error, any}
end
