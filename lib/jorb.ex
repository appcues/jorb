defmodule Jorb do
  @moduledoc ~S"""
  # Jorb

  I uh, I say you did a great _jorb_ out there

  ## What

  Jorb is a simple jobs processing system for Elixir

  ## How

  Modules use `Jorb.Job` and implement its' `c:queue_name/0` and `c:perform/1` callbacks

  Example:

  ```
  defmodule Demo.Jobs.TestJob do
     use Jorb.Job

     def queue_name, do: "test"
     def perform(name) do
       IO.puts("Hello #{name}")
     end
  end
  ```

  Then, queue jobs to be performed later with `perform_async`

  ```Demo.Jobs.TestJob.perform_async("Andy")```

  And sometime later "Hello Andy" will be output to the console


  """
end
