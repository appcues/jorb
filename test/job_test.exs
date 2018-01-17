defmodule Jorb.JobTest do
  use ExUnit.Case
  doctest Jorb.Job

  alias Jorb.Test.{BadJob,GoodJob}

  test "bad job raises" do
    assert_raise(RuntimeError, fn ->
      BadJob.queue_name
    end)

    assert_raise(RuntimeError, fn ->
      BadJob.perform("bogus")
    end)
  end

  test "good job does not raise" do
    assert "good_job" == GoodJob.queue_name()
  end
end
