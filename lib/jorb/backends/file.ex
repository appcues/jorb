defmodule Jorb.Backends.File do
  @moduledoc ~S"""
  File-based backend for light queueing.

  You probably don't want to use this for production load.
  """
  @behaviour Jorb.Backend

  def setup(queue_name) do
    unless File.exists?(queue_dir(queue_name)) do
      queue_dir(queue_name) |> File.mkdir_p!()
    end
  end

  def enqueue(queue_name, payload) do
    with now <- :erlang.system_time(:milli_seconds),
         message_name <- "#{now}.json",
         {:ok, body} <- Poison.encode(payload),
         dir <- queue_dir(queue_name),
         path <- Path.join(dir, message_name),
         final_payload <- %{receipt_handle: path, body: body},
         {:ok, encoded} <- Poison.encode(final_payload),
         :ok <- File.write(path, encoded) do
      {:ok, final_payload}
    else
      err -> err
    end
  end

  def dequeue(queue_name) do
    with dir <- queue_dir(queue_name),
         {:ok, files} <- File.ls(dir),
         message_file <- List.first(files),
         message_path <- Path.join(dir, message_file),
         {:ok, raw_message} <- File.read(message_path),
         {:ok, message} <- Poison.decode(raw_message) do
      message
      |> atomize_message_keys
      |> List.wrap()
    else
      _ -> []
    end
  end

  def finalize(_queue_name, message) do
    File.rm(message[:receipt_handle])
  end

  def purge(queue_name) do
    File.rm_rf(queue_dir(queue_name))
  end

  defp queue_dir(queue_name) do
    Path.join(["tmp", "jorb", queue_name])
  end

  defp atomize_message_keys(message) do
    message
    |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, String.to_existing_atom(key), val) end)
  end
end
