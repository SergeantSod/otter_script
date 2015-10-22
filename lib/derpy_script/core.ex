defmodule DerpyScript.Core do

  def handle_function("print", some_string) do
    IO.puts some_string
  end

  def handle_infix("<=", left, right) do
    left <= right
  end

end
