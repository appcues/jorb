defmodule Jorb.Backend.File do
  @moduledoc ~S"""
  File-based backend for light queueing.

  You probably don't want to use this for production load.

  Restricted to 1 fetching process per queue currently.
  """
  @behaviour Jorb.Backend
  def setup(queue_name) do
    if Application.get_env(:jorb, :fetching_processes) > 1 do
      raise "File queueing backend is currently restricted to 1 (or 0) processes per queue"
    end

    unless File.exists?(queue_dir(queue_name)) do
      queue_dir(queue_name) |> File.mkdir_p!()
    end

    :ok
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

  def pull(queue_name) do
    dir = queue_dir(queue_name)

    case File.ls(dir) do
      {:ok, []} ->
        {:ok, []}

      {:ok, files} ->
        message_file = List.first(files)
        message_path = Path.join(dir, message_file)

        with {:ok, raw_message} <- File.read(message_path),
             {:ok, message} <- Poison.decode(raw_message) do
          out =
            message
            |> atomize_message_keys
            |> List.wrap()

          {:ok, out}
        else
          err -> err
        end

      err ->
        err
    end
  end

  def finalize(_queue_name, message) do
    File.rm(message[:receipt_handle])
  end

  def purge(queue_name) do
    case File.rm_rf(queue_dir(queue_name)) do
      {:ok, _files} -> :ok
      {:error, reason, _files} -> {:error, reason}
    end
  end

  defp queue_dir(queue_name) do
    Path.join(["tmp", "jorb", queue_name])
  end

  defp atomize_message_keys(message) do
    message
    |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, String.to_existing_atom(key), val) end)
  end
end
