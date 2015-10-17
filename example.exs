#!/bin/env elixir

defmodule TermParser do
  import Parsable.Factory

  def script do
    many line
  end


  def line do
    match [ optional(whitespace), statement, optional(whitespace), "\n" ],
          [ _,                    result,    _,                    _    ], do: result
  end

  def whitespace do
    match ~r/(\s)+/, _, do: :whitespace
  end

  def statement do
    choice(assignment, invocation)
  end

  def assignment do
    match [identifier, optional(whitespace), "=", optional(whitespace), expression],
          [lhs       , _                   , _  , _,                    rhs       ] do

      {:assignment, lhs, rhs}
    end
  end

  def identifier do
    match ~r/(\w+)/, [name], do: name
  end

  def reference do
    match identifier, x, do: {:reference, x}
  end

  def literal do
    match ~r/(\d+)/, [digits] do
      {result, ""} = Integer.parse digits
      result
    end
  end

  def expression do
    choice(reference, literal, invocation)
  end

  def invocation do
    match [identifier,    "(", optional(whitespace), optional(expression_list) , optional(whitespace),")"],
          [function_name,  _,  _,                    a                         , _,                    _ ] do

      arguments = case a do
        nil ->
          []
        _   ->
          a
      end
      {:incovation, function_name, arguments}
    end
  end

  def expression_list do
    match [lazy(expression), many(expression_tail)],
          [head,             tail                 ], do: [head | tail]
  end

  def expression_tail do
    match [optional(whitespace), ",", optional(whitespace), lazy(expression)],
          [_,                     _,  _,                    result          ], do: result
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
