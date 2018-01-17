defmodule Jorb.Test.GoodJob do
  use Jorb.Job

  def queue_name, do: "good_job"
  def perform(name) do
    IO.puts "Hewwo #{name}"
  end
end
