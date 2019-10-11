defmodule Jorb.UtilsTest do
  use ExUnit.Case, async: false
  import Jorb.Utils

  test "with_ets_lock" do
    table = :ets.new(:whatever, [:duplicate_bag, :public])

    spawn(fn ->
      IO.inspect("yup")
      Process.sleep(200)

      with_ets_lock(
        table,
        :key,
        fn _ ->
          IO.inspect("yup locked")
          :ets.insert(table, {:key, :yup})
          IO.inspect("yup assigned")
        end,
        5000,
        :yup
      )
      |> IO.inspect(label: "yup rv")
    end)

    spawn(fn ->
      IO.inspect("nope")

      with_ets_lock(
        table,
        :key,
        fn _ ->
          IO.inspect("nope locked")
          Process.sleep(500)
          :ets.insert(table, {:key, :nope})
          IO.inspect("nope assigned")
        end,
        5000,
        :nope
      )
      |> IO.inspect(label: "nope rv")
    end)

    Process.sleep(1000)

    with_ets_lock(
      table,
      :key,
      fn
        [{:key, item}] -> assert :yup = item
        [] -> assert false
      end,
      5000,
      :assert
    )
    |> IO.inspect()
  end
end
