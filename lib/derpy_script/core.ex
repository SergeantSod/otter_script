#TODO Naming
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

end
