defmodule Jorb.Backend.SQSTest do
  use ExUnit.Case, async: false
  alias Jorb.Backend.SQS

  test "create, enqueue, read, purge, delete" do
    queue = UUID.uuid4()
    message = %{"hi" => "mom"}

    read_opts = [
      read_duration: 1,
      read_timeout: 1000,
      read_batch_size: 1
    ]

    assert :ok = SQS.create_queue(queue, visibility_timeout: 1)
    assert :ok = SQS.write_messages(queue, [message], [])
    wait()
    assert {:ok, [%{body: message}]} = SQS.read_messages(queue, read_opts)

    # test purge
    assert :ok = SQS.purge_queue(queue, [])
    wait()
    assert {:ok, []} = SQS.read_messages(queue, read_opts)

    # test visibility_timeout
    assert :ok = SQS.write_messages(queue, [message], visibility_timeout: 1)
    wait()
    assert {:ok, [%{body: message}]} = SQS.read_messages(queue, read_opts)
    wait()
    assert {:ok, []} = SQS.read_messages(queue, read_opts)
    Process.sleep(31000)
    assert {:ok, [%{body: message}]} = SQS.read_messages(queue, read_opts)

    assert :ok = SQS.delete_queue(queue, [])
  end

  defp wait, do: Process.sleep(50)
end
