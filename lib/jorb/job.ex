defmodule Jorb.Job do
  @moduledoc ~S"""
  `Jorb.Job` defines the mixin that you will use to create jobs.

  Define the `c:queue_name/0` and `c:perform/1` callbacks in the including module.

  Jorb will not take care of creating queues for you, that must be done ahead of time.
  """

  @callback queue_name :: String.t()
  @callback perform(any) :: :ok

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Jorb.Job

      alias ExAws.SQS

      @doc ~S"""
      Queue a job to be performed later. Send the name of the enqueueing module along
      so we know which module to send the params later
      """
      @spec perform_async(Poison.Encoder.t()) :: :ok
      @timed key: :auto
      def perform_async(payload) do
        # Include who sent the message, so we can figure out who's gotta deal with it later
        final_payload = %{target: __MODULE__, body: payload}
        SQS.send_message(queue_name(), Poison.encode!(final_payload)) |> ExAws.request!()
        :ok
      end

      def queue_name, do: raise("queue_name must be defined")
      def perform(_args), do: raise("perform must be defined")

      defoverridable queue_name: 0, perform: 1
    end
  end
end
