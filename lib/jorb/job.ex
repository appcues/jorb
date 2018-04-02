defmodule Jorb.Job do
  @moduledoc ~S"""
  `Jorb.Job` defines the mixin that you will use to create jobs.

  Define the `c:queue_name/0` and `c:perform/1` callbacks in the including module.

  Jorb will not take care of creating queues for you, that must be done ahead of time.
  """

  @callback queue_name :: String.t()
  @callback perform(any) :: :ok | :skipped | :error

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Jorb.Job

      @doc ~S"""
      Queue a job to be performed later. Send the name of the enqueueing module along
      so we know which module to send the params later
      """
      @spec perform_async(Poison.Encoder.t()) :: :ok
      def perform_async(payload) do
        # Include who sent the message, so we can figure out who's gotta deal with it later
        body_payload = %{target: __MODULE__, body: payload}
        queue_name = queue_name()
        Jorb.backend().enqueue(queue_name(), body_payload)
        :ok
      end

      def queue_name, do: raise("queue_name must be defined")
      def perform(_args), do: raise("perform must be defined")

      defoverridable queue_name: 0, perform: 1
    end
  end
end
