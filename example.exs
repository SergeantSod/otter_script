#!/bin/env elixir

defmodule TermParser do
  import Parsable.Factory

  def script do
    many line
  end

  def line do
    "\n"
  end
end

defmodule Runner do
  def run do
    case System.argv do
      [file_name] ->
        run file_name
      _ ->
        IO.puts "Give the filename as the one and only argument."
        System.halt(1)
    end
  end

  def run(file_name) do
    file_name
      |> File.read!
      |> Parsable.parse!(TermParser.script)
      |> IO.inspect
  end
end

Runner.run
