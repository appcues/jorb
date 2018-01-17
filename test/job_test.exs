defmodule TestJob do
  use Jorb.Job

  def queue_name, do: "test"
  def perform(_arg) do
    IO.puts "Hello!"
  end
end

defmodule BadJob do
  use Jorb.Job
end

defmodule Jorb.JobTest do
  use ExUnit.Case
  doctest Jorb.Job

  test "bad job raises" do
    assert_raise(RuntimeError, fn ->
      BadJob.queue_name
    end)

    assert_raise(RuntimeError, fn ->
      BadJob.perform("bogus")
    end)
  end
end
