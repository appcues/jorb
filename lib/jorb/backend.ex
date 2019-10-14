defmodule Jorb.Backend do
  @moduledoc ~S"""
  The `Jorb.Backend` behaviour represents a queueing abstraction.
  """
  @type queue :: String.t()
  @type message :: map
  @type opts :: Keyword.t()

  @callback create_queue(queue, opts) :: :ok | {:error, any}
  @callback delete_queue(queue, opts) :: :ok | {:error, any}
  @callback purge_queue(queue, opts) :: :ok | {:error, any}
  @callback write_messages(queue, [message], opts) :: :ok | {:error, any}
  @callback read_messages(queue, opts) :: {:ok, [message]} | {:error, any}
  @callback delete_message(queue, message, opts) :: :ok | {:error, any}
end
