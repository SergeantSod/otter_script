#TODO Naming
defmodule OtterScript.Core do

  import OtterScript.Interpreter.State

  def expose(state) do
    #TODO Make less ugly
    #TODO Add function to expose other native modules
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
