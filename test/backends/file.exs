defmodule Jorb.Backends.FileTest do
  use ExUnit.Case, async: true

  setup do
    queue = "test"
    message = %{target: Jorb.Test.GoodJob, body: "payload"}

    Jorb.Backends.File.setup(queue)

    on_exit(fn ->
      Jorb.Backends.File.purge(queue)
    end)

    {:ok, message: message, queue: queue}
  end

  describe "enqueuing messages" do
    test "enqueue writes a message to the filesystem", context do
      {:ok, message} = Jorb.Backends.File.enqueue(context[:queue], context[:message])
      assert File.exists?(message[:receipt_handle])
    end
  end

  describe "dequeuing messages" do
    test "dequeuing retuns an array of queued messages", context do
      {:ok, message} = Jorb.Backends.File.enqueue(context[:queue], context[:message])
      assert Jorb.Backends.File.dequeue(context[:queue]) == [message]
    end
  end

  describe "finalizing messages" do
    test "finalizing removes the file from disk", context do
      {:ok, message} = Jorb.Backends.File.enqueue(context[:queue], context[:message])
      :ok = Jorb.Backends.File.finalize(context[:queue], message)
      assert !File.exists?(message[:receipt_handle])
    end
  end
end
