defmodule DerpyScript.Runner do
  alias DerpyScript.Interpreter
  alias DerpyScript.Core
  alias DerpyScript.Parser

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
    Parsable.parse!(script, Parser.script)
  end

  def debug(script) do
    script
      |> parse
      |> IO.inspect
  end

  def run(script) do
    script
      |> parse
      |> Interpreter.evaluate(%Interpreter.State{core: Core})
      |> elem(0)
  end

end
