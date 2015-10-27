defmodule DerpyScript.Core do

  import DerpyScript.Interpreter.State

  def expose(state) do
    state
      |> pure_core_function(:print, 1, &IO.puts/1)
      |> pure_core_function(:not, 1, &(!&1) )
      |> pure_core_function(:<=, 2, &(&1 <= &2))
      |> pure_core_function(:>=, 2, &(&1 >= &2))
      |> pure_core_function(:==, 2, &(&1 == &2))
      |> pure_core_function(:-,  2, &(&1 - &2))
      |> pure_core_function(:+,  2, &(&1 + &2))
      |> pure_core_function(:*,  2, &(&1 * &2))
      |> pure_core_function(:/,  2, &(&1 / &2))
  end

  # def function("print", arguments) do
  #   arguments
  #     |> Enum.join
  #     |> IO.puts
  #   nil
  # end
  #
  # def function("not", [something]) do
  #   not(something)
  # end
  #
  # def operator("<=", left, right) do
  #   left <= right
  # end
  #
  # def operator(">=", left, right) do
  #   left >= right
  # end
  #
  # def operator("==", left, right) do
  #   left == right
  # end
  #
  # def operator("-", left, right) do
  #   left - right
  # end
  #
  # def operator("+", left, right) do
  #   left + right
  # end
  #
  # def operator("*", left, right) do
  #   left * right
  # end
  #
  # def operator("/", left, right) do
  #   left / right
  # end

end
