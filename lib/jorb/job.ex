defmodule Jorb.Job do

  @moduledoc ~S"""
  `Jorb.Job` defines the mixin that you will use to create jobs.
  """

  @callback queue_name :: String.t
  @callback perform(any) :: :ok

  @doc false
  defmacro __using__(_opts) do
    quote do
      require Logger

      @behaviour Jorb.Job

      alias ExAws.SQS

      @spec perform_async(Map.t) :: :ok
      def perform_async(payload) do
        before = :erlang.monotonic_time(:milli_seconds)

        # Include who sent the message, so we can figure out who's gotta deal with it later
        final_payload = %{ target: __MODULE__, body: payload }
        SQS.send_message(queue_name(), Poison.encode!(final_payload)) |> ExAws.request!

        Logger.debug("SQS write time: #{:erlang.monotonic_time(:milli_seconds) - before}")

        :ok
      end

      def queue_name, do: raise "queue_name must be defined"
      def perform(_args), do: raise "perform must be defined"

      defoverridable [queue_name: 0, perform: 1]
    end
  end
end
