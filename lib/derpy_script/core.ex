defmodule DerpyScript.Core do

  def handle_function("print", [something]) do
    IO.puts something
  end

  def handle_function("not", [something]) do
    not(something)
  end

  def handle_infix("<=", left, right) do
    left <= right
  end

  def handle_infix(">=", left, right) do
    left >= right
  end

  def handle_infix("==", left, right) do
    left == right
  end

  def handle_infix("-", left, right) do
    left - right
  end

  def handle_infix("+", left, right) do
    left + right
  end

end
