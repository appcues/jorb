defmodule Jorb.UtilsTest do
  use ExUnit.Case, async: false
  import Jorb.Utils

  test "with_ets_lock" do
    table = :ets.new(:whatever, [:set, :public])

    spawn(fn ->
      Process.sleep(50)

      with_ets_lock(table, :key, fn _ ->
        :ets.insert(table, {:key, :yup})
      end)
    end)

    spawn(fn ->
      with_ets_lock(table, :key, fn _ ->
        Process.sleep(100)
        :ets.insert(table, {:key, :nope})
      end)
    end)

    Process.sleep(200)

    with_ets_lock(table, :key, fn
      [{:key, item}] -> assert :yup = item
      [] -> assert false
    end)
  end
end