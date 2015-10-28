defmodule DerpyScript.Runner do
  alias DerpyScript.Interpreter
  alias DerpyScript.Core

  def main(arguments) do
    case arguments do
      [file_name] ->
        file_name
          |> File.read!
          |> run
      ["--parse", file_name] ->
        file_name
          |> File.read!
          |> debug
      _ ->
        IO.puts "Give the filename as the one and only argument."
        System.halt(1)
    end
  end

  defp parse(script) do
    Parsable.Core.parse!(script, DerpyScript.Parser.Core.script)
  end

  def debug(script) do
    script
      |> parse
      |> IO.inspect
  end

  def run(script) do
    initial_state = DerpyScript.Core.expose(%Interpreter.State{})
    script
      |> parse
      |> Interpreter.evaluate(initial_state)
      |> elem(0)
  end

end
