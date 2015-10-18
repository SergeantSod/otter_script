#!/bin/env elixir

defmodule Parsers.InterspersedList do
  import Parsable.Factory

  def interspersed(content, separator) do
    match optional(interspersed!(content, separator)), result, do: (result || [])
  end

  def interspersed!(content, separator) do
    match [ content, many(tail_for(content, separator)) ],
          [ head,    tail                               ], do: [head | tail]
  end

  defp tail_for(content, separator) do
    match [ separator, content ],
          [ _,         result  ], do: result
  end

end

defmodule Parsers.Literals do
  import Parsable.Factory

  def integer do
    match ~r/(\d+)/, [digits] do
      {result, ""} = Integer.parse digits
      result
    end
  end

  def string do
    match ["\"", many(chunk), "\""],
          [_,    contents,    _   ] do

      Enum.join contents
    end
  end

  defp chunk do
    choice(escapes, normal_chunk)
  end

  defp normal_chunk do
    match ~r/([^"\\]+)/, [content], do: content
  end

  defp escapes do
    choice(
      escape("\\\\", "\\"),
      escape("\\\"", "\""),
      escape("\\n",  "\n")
    )
  end

  #TODO: This is generally useful and should be pulled into Parsable.Factory.
  #      the general pattern is: parse something, but represent it differently in the output.
  #      this is a weaker version of match, since it just puts in a constant, but still convenient.
  defp escape(source, target) do
    match source, _, do: target
  end

end

defmodule Parsers.Script do
  import Parsable.Factory

  def script do
    many line
  end

  def line do
    choice(expression_line, empty_line, comment_line)
  end

  def empty_line do
    match [space, "\n"], _, do: {:empty}
  end

  def comment_line do
    match [space, "#", ~r/(.*)/,  "\n"],
          [_,     _,   [content], _   ], do: {:comment, content}
  end

  def expression_line do
    match [ space, expression, space, "\n" ],
          [ _,     result,     _,     _    ], do: result
  end

  def space do
    optional(hardspace)
  end

  def hardspace do
    match ~r/( +)/, _, do: :hardspace
  end

  def expression do
    lazy choice(infix_expression, bare_expression)
  end

  def bare_expression do
    choice [
      literal,
      if_expression,
      function,
      assignment,
      invocation,
      recursion,
      block,
      reference
    ]
  end

  def function do
    match [ bracket_list(identifier), space, "=>", space, expression ],
          [ arguments,                _,     _,    _,     body       ] do

      {:function, arguments, body}
    end
  end

  def assignment do
    match [ identifier, space, choice("=", ":"), space, expression ],
          [ lhs,        _,     _,                _,     rhs        ] do

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
    import Parsers.Literals
    match choice(integer, string), value, do: {:literal, value}
  end

  def invocation do
    match [identifier,    bracket_list(expression) ],
          [function_name, arguments                ], do: {:invocation, function_name, arguments }
  end

  # def brackets do
  #   match [ "(", space, expression, space, ")"],
  #         [ _,   _,     result,     _,     _  ], do: result
  # end

  def recursion do
    match ["~", space, bracket_list(expression)],
          [_  , _,     result                  ], do: {:recursion, result}
  end

  def if_expression do
    else_clause = match [ space, "else", expression ],
                        [ _,     _,      result     ], do: result
    match ["if", space, expression, space, "then", space, expression, optional(else_clause)],
          [_,    _,     condition,  _,     _,      _,     if_case,    else_case            ]
        do
      { :if, condition, if_case, else_case }
    end
  end

  def block do
    block_start = [space, "do", space, "\n"]
    block_end   = [space, "end", space]
    match [ block_start, many(prevent(block_end, expression_line)), block_end ],
          [ _,           contents,                                  _         ], do: contents
  end

  def infix_expression do
    infix_expression choice ~w(- + * <= >= < > && || /)
  end

  defp infix_expression(operator) do
    match [ bare_expression, space, operator, space, bare_expression],
          [ left,            _,     op,       _,     right     ], do: {:infix, op, left, right}
  end

  defp bracket_list(content) do
    match [ "(", space, interspersed(content), space, ")" ],
          [ _,   _,     inner,                 _,     _,  ], do: inner
  end

  defp interspersed(content) do
    Parsers.InterspersedList.interspersed content, [space, ",", space]
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

  defmodule State do
    @derive [Access]
    defstruct bindings: %{}, stack: [], core: nil
  end

  def evaluate([], state) do
    {nil, state}
  end

  def evaluate([expression], state) do
    evaluate expression, state
  end

  def evaluate([expression | rest], state) do
    {_, new_state} = evaluate expression, state
    evaluate rest, new_state
  end

  def evaluate({:assignment, variable, expression}, state) do
    {result, new_state} = evaluate(expression, state)
    new_state = put_in new_state, [:bindings, variable], result
    {result, new_state}
  end

  def evaluate({:reference, variable_name}, state) do
    if Map.has_key? state.bindings, variable_name do
      {state.bindings[variable_name], state}
    else
      raise "Variable #{variable_name} is undefined."
    end
  end

  def evaluate({:invocation, function_name, arguments}, state) do
    {evaluated_arguments, new_state} = evaluate_sequence arguments, state
     result = do_invoke(new_state, function_name, evaluated_arguments)
    {result, new_state}
  end

  def evaluate({:literal, value}, state), do: {value, state}
  def evaluate({:comment, _},     state), do: {nil,   state}
  def evaluate({:empty},          state), do: {nil,   state}

  defp do_invoke(state, function_name, arguments) do
    apply(state.core, String.to_atom(function_name), arguments)
  end

  defp evaluate_sequence([], state) do
    {[], state}
  end

  defp evaluate_sequence([e | rest], state) do
    { result,                    new_state } = evaluate e, state
    { other_results,            last_state } = evaluate_sequence rest, new_state
    { [result | other_results], last_state }
  end

end

defmodule Runner do
  def run do
    case System.argv do
      [file_name] ->
        parse(file_name) |> run
      ["--parse", file_name] ->
        parse(file_name) |> print
      _ ->
        IO.puts "Give the filename as the one and only argument."
        System.halt(1)
    end
  end

  def parse(file_name) do
    file_name
      |> File.read!
      |> Parsable.parse!(Parsers.Script.script)
  end

  def print(script) do
    IO.inspect script
  end

  def run(script) do
    Interpreter.evaluate(script, %Interpreter.State{core: CoreFunctions})
  end

end

Runner.run
