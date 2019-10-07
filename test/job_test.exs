defmodule Jorb.TestJob do
  use Jorb.Job

  @impl true
  def read_queues, do: ["high_priority", "low_priority"]

  @impl true
  def write_queue(payload) do
    if payload["priority"] == "high" do
      "high_priority"
    else
      "low_priority"
    end
  end

  @impl true
  def perform(_payload) do
    :ok
  end
end

defmodule Jorb.JobTest do
  use ExUnit.Case
  doctest Jorb.Job

  @backend Jorb.Backend.Memory

  test "enqueue and workers" do
    Jorb.TestJob.enqueue(%{"n" => 1})
    Jorb.TestJob.enqueue(%{"n" => 2})
    Jorb.TestJob.enqueue(%{"n" => 3, "priority" => "high"})

    assert {:ok, [_, _]} = @backend.read_messages("low_priority", read_batch_size: 10)
    assert {:ok, [_]} = @backend.read_messages("high_priority", read_batch_size: 10)

    {:ok, pid} =
      Jorb.TestJob.workers(worker_count: 1, read_interval: 10)
      |> Supervisor.start_link(strategy: :one_for_one)

    # Wait for work to be done
    Process.sleep(50)

    assert {:ok, []} = @backend.read_messages("low_priority", [])
    assert {:ok, []} = @backend.read_messages("high_priority", [])

    Supervisor.stop(pid)
  end
end
