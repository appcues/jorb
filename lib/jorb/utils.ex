defmodule Jorb.Utils do
  @moduledoc false

  @spin_delay 2

  defp now, do: :erlang.system_time(:millisecond)

  @doc ~S"""
  Locks a key in ETS and invokes `fun` on the `{key, value}` tuples for
  that key.

  If the key is already locked, this function spins until the lock is
  released or timeout is reached.
  """
  @spec with_ets_lock(:ets.tab(), any, ([{any, any}] -> any), non_neg_integer | :infinity) ::
          :ok | :timeout
  def with_ets_lock(table, key, fun, timeout \\ 5000) do
    until = if timeout == :infinity, do: :infinity, else: now() + timeout
    with_ets_lock_until(table, key, fun, until)
  end

  defp with_ets_lock_until(table, key, fun, until) do
    lock_key = {:lock, key}
    now = now()

    case :ets.lookup(table, lock_key) do
      [] ->
        :ets.insert(table, {lock_key, until})
        :ets.lookup(table, key) |> fun.()
        :ets.delete(table, lock_key)
        :ok

      [{_lock_key, time}] ->
        cond do
          until == :infinity || now < time ->
            Process.sleep(@spin_delay)
            with_ets_lock_until(table, key, fun, until)

          :else ->
            :ets.delete(table, lock_key)
            :timeout
        end
    end
  end
end
