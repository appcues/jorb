defmodule Jorb.WriterTestJob do
  use Jorb.Job

  @impl true
  def read_queues, do: ["q"]

  @impl true
  def write_queue, do: "q"

  @impl true
  def perform(_payload), do: :ok
end

defmodule Jorb.WriterTest do
  use ExUnit.Case, async: false

  @backend Jorb.Backend.Memory

  test "writers" do
    Jorb.WriterTestJob.read_queues() |> Enum.each(&@backend.create_queue(&1, []))

    {:ok, pid} =
      Jorb.WriterTestJob.workers(reader_count: 0, writer_count: 1)
      |> Supervisor.start_link(strategy: :one_for_one)

    ## ensure that periodic flushes are occurring
    1..3 |> Enum.each(&Jorb.WriterTestJob.enqueue(%{"n" => &1}))
    assert {:ok, []} = @backend.read_messages("q", read_batch_size: 10)
    Process.sleep(1100)
    assert {:ok, [_, _, _]} = @backend.read_messages("q", read_batch_size: 10)

    assert :ok = @backend.purge_queue("q", [])

    # ensure that we flush immediately when write_batch_size is reached
    1..5 |> Enum.each(&Jorb.WriterTestJob.enqueue(%{"n" => &1}))
    assert {:ok, [_, _, _, _]} = @backend.read_messages("q", read_batch_size: 10)
    Process.sleep(1100)
    assert {:ok, [_, _, _, _, _]} = @backend.read_messages("q", read_batch_size: 10)

    Supervisor.stop(pid)

    Jorb.WriterTestJob.read_queues() |> Enum.each(&@backend.delete_queue(&1, []))
  end
end
