defmodule DerpyScript.Runner do
  alias DerpyScript.Interpreter
  alias DerpyScript.Core
  alias DerpyScript.Parser

  def main(arguments) do
    case arguments do
      [file_name] ->
        parse(file_name) |> run
      ["--parse", file_name] ->
        parse(file_name) |> print
      _ ->
        IO.puts "Give the filename as the one and only argument."
        System.halt(1)
    end
  end

  defp parse(file_name) do
    file_name
      |> File.read!
      |> Parsable.parse!(Parser.script)
  end

  defp print(script) do
    IO.inspect script
  end

  defp run(script) do
    Interpreter.evaluate(script, %Interpreter.State{core: Core})
  end

end
