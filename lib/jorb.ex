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
  |> Supervisor.start_link()
  ```

  """

  @defaults [
    backend: Jorb.Backend.Memory,
    write_interval: 1000,
    write_batch_size: 1,
    read_duration: 0,
    read_interval: 1000,
    read_batch_size: 1,
    read_timeout: 2000,
    perform_timeout: 5000,

    ## Overridden at runtime below
    worker_count: nil
  ]

  defp default(:worker_count), do: System.schedulers_online()

  defp default(param), do: @defaults[param]

  @doc false
  @spec config(atom, Keyword.t(), atom) :: any
  def config(param, opts \\ [], module \\ :none) do
    jorb_env = Application.get_all_env(:jorb)
    module_env = jorb_env[module]
    opts[param] || module_env[param] || jorb_env[param] || default(param)
  end
end
