defmodule Jorb.Job do
  @moduledoc ~S"""
  Modules that `use Jorb.Job` can enqueue, read, and perform jobs.
  These modules must implement the `Jorb.Job` behaviour.

  In addition to the callbacks defined in `Jorb.Job`, these modules also
  export the `enqueue/2`, `work/1`, and `workers/1` functions.  See the
  documention below for `enqueue/3`, `work/2`, and `workers/2`.

  See `Jorb` for more documentation.
  """

  @type queue :: String.t()

  @type message :: map()

  @doc ~S"""
  List of queues to fetch jobs from, given in highest-priority-first order.
  """
  @callback read_queues :: [queue]

  @doc ~S"""
  Queue to write to, for the given payload.
  Implement this or `c:write_queue/0`.
  """
  @callback write_queue(any) :: queue

  @doc ~S"""
  Queue to write to.
  Implement this or `c:write_queue/1`.
  """
  @callback write_queue :: queue

  @doc ~S"""
  Performs the given work.  Behind the scenes, the message from which the
  work originated will be deleted from the queue if this function returns
  `:ok`.
  """
  @callback perform(any) :: :ok | :error

  @optional_callbacks write_queue: 0, write_queue: 1

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Jorb.Job

      def write_queue(_payload), do: write_queue()

      def write_queue(), do: raise("either write_queue/1 or write_queue/0 must be defined")

      defoverridable Jorb.Job

      @doc ~S"""
      Queue a job to be performed by this module's `perform/1` function
      later.
      """
      @spec enqueue(any, Keyword.t()) :: :ok | {:error, String.t()}
      def enqueue(payload, opts \\ []), do: Jorb.Job.enqueue(__MODULE__, payload, opts)

      @doc ~S"""
      Attempt to fetch jobs to do, reading from the first item in
      `read_queues/0` that has messages.  For each message received,
      `perform/1` is invoked, deleting the message if the return value
      is `:ok`.
      """
      @spec work(Keyword.t()) :: :ok | {:error, String.t()}
      def work(opts \\ []), do: Jorb.Job.work(__MODULE__, opts)

      @doc ~S"""
      Returns a list of one or more child specs for GenServers that
      execute `work(opts)` forever.
      """
      @spec workers(Keyword.t()) :: [:supervisor.child_spec()]
      def workers(opts \\ []), do: Jorb.Job.workers(__MODULE__, opts)
    end
  end

  @doc ~S"""
  Queue a job to be performed by this module's `perform/1` function
  later.

  Intended for use through modules that `use Jorb.Job`.
  """
  @spec enqueue(atom, any, Keyword.t()) :: :ok | {:error, String.t()}
  def enqueue(module, payload, opts) do
    message = %{"target" => module, "body" => payload}
    queue = module.write_queue(payload)
    Jorb.config(:backend, [], module).enqueue_message(queue, message, opts)
  end

  @doc ~S"""
  Returns a list of one or more child specs for GenServers that
  execute `work(opts)` forever.

  Intended for use through modules that `use Jorb.Job`.
  """
  @spec workers(atom, Keyword.t()) :: [:supervisor.child_spec()]
  def workers(module, opts) do
    1..Jorb.config(:worker_count, opts, module)
    |> Enum.map(fn i ->
      %{
        id: {module, :worker, i},
        start: {Jorb.Worker, :start_link, [[{:module, module} | opts]]},
        type: :worker,
        restart: :permanent,
        shutdown: 5000
      }
    end)
  end

  @doc ~S"""
  Attempt to fetch jobs to do, reading from the first item in
  `read_queues/0` that has messages.  For each message received,
  `perform/1` is invoked, deleting the message if the return value
  is `:ok`.

  Intended for use through modules that `use Jorb.Job`.
  """
  @spec work(atom, Keyword.t()) :: :ok | {:error, String.t()}
  def work(module, opts) do
    queues = module.read_queues()

    duration = Jorb.config(:read_duration, opts, module)
    batch_size = Jorb.config(:read_batch_size, opts, module)
    read_timeout = Jorb.config(:read_timeout, opts, module)
    perform_timeout = Jorb.config(:perform_timeout, opts, module)

    read_opts = [
      read_duration: duration,
      read_batch_size: batch_size,
      read_timeout: read_timeout
    ]

    case read_from_queues(queues, read_opts, module) do
      {:ok, messages, queue} ->
        tasks = Enum.map(messages, &performance_task(&1, queue, opts, module))

        Task.yield_many(tasks, perform_timeout)
        |> Enum.each(fn {task, result} ->
          if result == nil, do: Task.shutdown(task)
        end)

        :ok

      :none ->
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  # @spec performance_task(message, queue, Keyword.t(), atom) :: Task.t()
  defp performance_task(message, queue, opts, module) do
    backend = Jorb.config(:backend, opts, module)

    job_module =
      case message["target"] do
        target when is_binary(target) -> String.to_existing_atom(target)
        target -> target
      end

    body =
      case message["body"] do
        body when is_binary(body) -> Poison.decode!(body)
        body -> body
      end

    Task.async(fn ->
      case job_module.perform(body) do
        :ok -> backend.delete_message(queue, message, opts)
        _ -> :oh_well
      end
    end)
  end

  # @spec read_from_queues([queue], Keyword.t(), atom) ::
  #        {:ok, [message], queue} | :none | {:error, String.t()}
  defp read_from_queues([], _opts, _module), do: :none

  defp read_from_queues([queue | rest], opts, module) do
    backend = Jorb.config(:backend, opts, module)

    case backend.read_messages(queue, opts) do
      {:ok, []} -> read_from_queues(rest, opts, module)
      {:ok, messages} -> {:ok, messages, queue}
      error -> error
    end
  end
end
