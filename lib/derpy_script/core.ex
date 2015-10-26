defmodule DerpyScript.Core do

  def function("print", arguments) do
    arguments
      |> Enum.join
      |> IO.puts
    nil
  end

  def function("not", [something]) do
    not(something)
  end

  def operator("<=", left, right) do
    left <= right
  end

  def operator(">=", left, right) do
    left >= right
  end

  def operator("==", left, right) do
    left == right
  end

  def operator("-", left, right) do
    left - right
  end

  def operator("+", left, right) do
    left + right
  end

  def operator("*", left, right) do
    left * right
  end

  def operator("/", left, right) do
    left / right
  end


end
