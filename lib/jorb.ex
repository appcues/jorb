defmodule Jorb do
  @moduledoc ~S"""
  # Jorb

  I uh, I say you did a great _jorb_ out there

  ## What

  Jorb is a simple queue-based jobs processing system for Elixir.
  Works great with Amazon SQS.

  ## How

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
  HelloWorld.Job.work(read_timeout: 1000, perform_timeout: 5000)

  # poll queues forever
  HelloWorld.Job.workers(worker_count: 2, read_interval: 1000)
  |> Supervisor.start_link(strategy: :one_for_one)
  ```

  ## Installation

  Put the following into your `mix.exs` file's `deps` function:

      {:jorb, "~> 0.3.0"}

  ## Configuration

  In order of priority, configs can be provided by:

  * Passing options in the `opts` parameter to each function
  * Configuring your job module in `config/config.exs`:

      config :jorb, HelloWorld.Job, [read_timeout: 5000]

  * Configuring global Jorb settings in `config/config.exs`:

      config :jorb, write_batch_size: 10

  Options:

  * `:backend` - the module implementing `Jorb.Backend`, default
    `Jorb.Backend.Memory`. You should set this to something
    else (like `Jorb.Backend.SQS` in production.
  * `:reader_count` - number of read workers to launch per job module,
    default `System.schedulers_online()`.
  * `:writer_count` - number of message batch writers to launch, default 1.
  * `:write_batch_size` - number of messages to write at once, default 1.
  * `:write_interval` - milliseconds to wait before flushing outgoing
     messages, default 1000.
  * `:write_queues` - list of queue names that might be written to.
  * `:read_batch_size` - number of messages to read at once, default 1.
  * `:read_interval` - milliseconds to sleep between fetching messages,
     default 1000.
  * `:read_duration` - milliseconds to hold connection open when polling
    for messages, default 1000.
  * `:read_timeout` - milliseconds before giving up when reading messages,
    default 2000.
  * `:perform_timeout` - milliseconds before giving up when performing a
    single job, default 5000.

  """

  @defaults [
    backend: Jorb.Backend.Memory,
    writer_count: 1,
    write_interval: 1000,
    write_batch_size: 1,
    read_duration: 0,
    read_interval: 1000,
    read_batch_size: 1,
    read_timeout: 2000,
    perform_timeout: 5000,

    ## Overridden at runtime below
    reader_count: nil
  ]

  defp default(:reader_count), do: System.schedulers_online()

  defp default(param), do: @defaults[param]

  @doc false
  @spec config(atom, Keyword.t(), atom) :: any
  def config(param, opts \\ [], module \\ :none) do
    jorb_env = Application.get_all_env(:jorb)
    module_env = jorb_env[module]
    opts[param] || module_env[param] || jorb_env[param] || default(param)
  end
end
