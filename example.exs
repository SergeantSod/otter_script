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
    match ~r/( +)/, _, do: :whitespace
  end

  def statement do
    choice(assignment, expression)
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
    choice(literal, invocation, reference)
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
      {:invocation, function_name, arguments}
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

defmodule CoreFunctions do
  def print(value) do
    IO.puts value
  end

  def add(a,b) do
    a + b
  end

  def mult(a, b) do
    a * b
  end
end

defmodule Interpreter do

  def interpret(script, core_functions, top_level_bindings \\ %{})

  def interpret(script, core_functions, top_level_bindings) when is_list(script) do
    Enum.reduce script, top_level_bindings, fn(statement, bindings) ->
      interpret(statement, core_functions, bindings)
    end
  end

  def interpret({:assignment, variable, expression}, core_functions, bindings) do
    Map.put bindings, variable, evaluate(expression, core_functions, bindings)
  end

  def interpret(other, core_functions, bindings) do
    evaluate(other, core_functions, bindings)
    bindings
  end

  def evaluate({:reference, variable_name}, _, bindings) do
    if Map.has_key? bindings, variable_name do
      Map.get bindings, variable_name
    else
      raise "Variable #{variable_name} is undefined."
    end
  end

  def evaluate({:invocation, function_name, arguments}, core_functions, bindings) do
    evaluated_arguments = Enum.map arguments, fn (a) ->
      evaluate(a, core_functions, bindings)
    end
    apply(core_functions, String.to_atom(function_name), evaluated_arguments)
  end

  def evaluate(literal, _, _) when is_number(literal), do: literal
end

defmodule Runner do
  def run do
    case System.argv do
      [file_name] ->
        run file_name
      ["--debug", file_name] ->
        debug file_name
      _ ->
        IO.puts "Give the filename as the one and only argument."
        System.halt(1)
    end
  end

  def parse(file_name) do
    file_name
      |> File.read!
      |> Parsable.parse!(TermParser.script)
  end

  def debug(file_name) do
    file_name |> parse |> IO.inspect
  end

  def run(file_name) do
    file_name |> parse |> Interpreter.interpret(CoreFunctions)
  end

end

Runner.run
