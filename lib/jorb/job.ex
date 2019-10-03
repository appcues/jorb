defmodule Jorb.Job do
  @moduledoc ~S"""
  `Jorb.Job` defines the mixin that you will use to create and execute jobs.

  Define your job module:

  ```
  defmodule HelloWorld.Job do
    use Jorb.Job

    def read_queues do
      ["high_priority_greetings", "regular_greetings"]
    end

    def write_queue(greeting) do
      if greeting["name"] == "Zeke" do
        "high_priority_greetings"
      else
        "regular_greetings"
      end
    end

    def perform(greeting) do
      IO.puts "Hello, #{greeting["name"]}!"
      :ok
    end
  end
  ```

  Enqueue work:

  ```
  HelloWorld.Job.enqueue(%{"name" => "Ray"})
  ```

  Perform work:

  ```
  # poll queues once
  HelloWorld.Job.fetch_and_perform(fetch_timeout: 1000, perform_timeout: 5000)

  # poll queues forever
  HelloWorld.Job.fetchers(count: 2, fetch_interval: 1000)
  |> Supervisor.start_link()
  ```
  """

  @type queue :: String.t()

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
      @spec enqueue(any) :: :ok | {:error, String.t()}
      def enqueue(payload), do: Jorb.Job.enqueue(__MODULE__, payload)

      @doc ~S"""
      Attempt to fetch jobs to do, reading from the first item in
      `read_queues/0` that has messages.  For each message received,
      `perform/1` is invoked, deleting the message if the return value
      is `:ok`.
      """
      @spec fetch_and_perform(Keyword.t()) :: :ok | {:error, String.t()}
      def fetch_and_perform(opts \\ []), do: Jorb.Job.fetch_and_perform(__MODULE__, opts)

      @doc ~S"""
      Returns a list of one or more child specs for GenServers that
      execute `fetch_and_perform(opts)` forever.
      """
      @spec fetchers(Keyword.t()) :: [:supervisor.child_spec()]
      def fetchers(opts), do: Jorb.Job.fetchers(__MODULE__, opts)
    end
  end

  @doc false
  @spec enqueue(atom, any) :: :ok | {:error, String.t()}
  def enqueue(module, payload) do
    message = %{target: module, body: payload}
    queue = module.write_queue(payload)
    Jorb.backend().enqueue(queue, message)
  end

  @doc false
  @spec fetch_and_perform(atom, Keyword.t()) :: :ok | {:error, String.t()}
  def fetch_and_perform(module, opts) do
  end

  @doc false
  @spec fetchers(atom, opts) :: [:supervisor.child_spec()]
  def fetchers(opts) do
  end
end
