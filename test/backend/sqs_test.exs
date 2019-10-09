defmodule Jorb.Backend.SQSTest do
  use ExUnit.Case, async: false
  alias Jorb.Backend.SQS

  test "create, enqueue, read, purge, delete" do
    queue = "jorb_test_queue"
    message = %{"hi" => "mom"}

    read_opts = [
      read_duration: 1,
      read_timeout: 1000,
      read_batch_size: 1
    ]

    assert :ok = SQS.create_queue(queue, queue_name: queue, visibility_timeout: 10)
    assert :ok = SQS.enqueue_message(queue, message, [])
    assert {:ok, [%{body: message}]} = SQS.read_messages(queue, read_opts)

    # test visibility_timeout
    #assert :none = SQS.read_messages(queue, read_opts)
    #Process.sleep(1000)
    #assert {:ok, [%{body: message}]} = SQS.read_messages(queue, read_opts)

    assert :ok = SQS.purge_queue(queue, [])
    assert :none = SQS.read_messages(queue, read_opts)

    assert :ok = SQS.delete_queue(queue, [])
  end
end
