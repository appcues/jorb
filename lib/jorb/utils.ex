defmodule Jorb.Utils do
  @moduledoc false

  defp now, do: :erlang.monotonic_time(:millisecond)

  @doc ~S"""
  Locks a key in ETS and invokes `fun` on the `{key, value}` tuples for
  that key.

  If the key is already locked, this function spins until the lock is
  released or timeout is reached.
  """
  @spec with_ets_lock(:ets.tab(), any, ([{any, any}] -> any), non_neg_integer | :infinity) ::
          :ok | :timeout
  def with_ets_lock(table, key, fun, timeout \\ 5000) do
    lock_key = {:lock, key}

    case :ets.lookup(table, lock_key) do
      [] ->
        :ets.insert(table, {lock_key, now()})
        :ets.lookup(table, key) |> fun.()
        :ets.delete(table, lock_key)
        :ok

      [{_lock_key, time}] ->
        time_since_lock = now() - time

        cond do
          timeout == :infinity ->
            with_ets_lock(table, key, fun, timeout)

          now() < time + timeout ->
            new_timeout = timeout - time_since_lock
            with_ets_lock(table, key, fun, new_timeout)

          :else ->
            :ets.delete(table, lock_key)
            :timeout
        end
    end
  end
end
