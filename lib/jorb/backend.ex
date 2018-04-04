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
  @type queue_name :: String.t()

  @callback setup(queue_name) :: :ok | no_return
  @callback enqueue(queue_name, map()) :: {:ok, map()} | {:error, any}
  @callback pull(queue_name) :: {:ok, [map()]} | {:error, any}
  @callback finalize(queue_name, map()) :: :ok | {:error, any}
  @callback purge(queue_name) :: :ok | {:error, any}

  @spec prefix_queue_name(queue_name) :: queue_name
  def prefix_queue_name(queue_name) do
    env = Application.get_env(:jorb, :environment) || 'dev'
    "#{env}_#{queue_name}"
  end
end
