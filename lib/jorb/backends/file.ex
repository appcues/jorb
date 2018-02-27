defmodule Jorb.Backends.File do
  @moduledoc ~S"""
  File-based backend for light queueing.

  You probably don't want to use this for production load.
  """
  @behaviour Jorb.Backend
  @queue_dir Path.join("tmp", "jorb")

  def enqueue(queue_name, payload) do
    ensure_queue_dir(queue_name)
    message_name = (:erlang.system_time(:milli_seconds) |> Integer.to_string()) <> ".json"

    # We're double-encoding the body here so we can have
    # parity with how messages come out of SQS
    final_payload = %{receipt_handle: message_name, body: Poison.encode!(payload)}

    Path.join(queue_dir(queue_name), message_name)
    |> File.write(Poison.encode!(final_payload))
  end

  def dequeue(queue_name) do
    ensure_queue_dir(queue_name)
    files = queue_dir(queue_name) |> File.ls!()

    if Enum.empty?(files) do
      []
    else
      files
      |> List.first()
      |> String.replace_prefix("", "#{queue_dir(queue_name)}/")
      |> File.read!()
      |> Poison.decode!()
      |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, String.to_atom(key), val) end)
      |> List.wrap()
    end
  end

  def finalize(queue_name, message) do
    ensure_queue_dir(queue_name)
    Path.join(queue_dir(queue_name), message[:receipt_handle]) |> File.rm()
  end

  defp ensure_queue_dir(queue_name) do
    unless File.exists?(queue_dir(queue_name)) do
      queue_dir(queue_name) |> File.mkdir_p!()
    end
  end

  defp queue_dir(queue_name) do
    Path.join(["tmp", "jorb", queue_name])
  end
end
