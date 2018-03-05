defmodule Jorb.Backend.FileTest do
  use ExUnit.Case, async: true

  setup do
    queue = "test"
    message = %{target: Jorb.Test.GoodJob, body: "payload"}

    Jorb.Backend.File.setup(queue)

    on_exit(fn ->
      Jorb.Backend.File.purge(queue)
    end)

    {:ok, message: message, queue: queue}
  end

  describe "enqueuing messages" do
    test "enqueue writes a message to the filesystem", context do
      {:ok, message} = Jorb.Backend.File.enqueue(context[:queue], context[:message])
      assert File.exists?(message[:receipt_handle])
    end
  end

  describe "pulling messages" do
    test "dequeuing retuns an array of queued messages", context do
      {:ok, message} = Jorb.Backend.File.enqueue(context[:queue], context[:message])
      assert Jorb.Backend.File.pull(context[:queue]) == {:ok, [message]}
    end
  end

  describe "finalizing messages" do
    test "finalizing removes the file from disk", context do
      {:ok, message} = Jorb.Backend.File.enqueue(context[:queue], context[:message])
      :ok = Jorb.Backend.File.finalize(context[:queue], message)
      assert !File.exists?(message[:receipt_handle])
    end
  end
end
