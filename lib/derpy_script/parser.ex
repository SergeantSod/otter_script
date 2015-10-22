
#TODO: This is generally useful and should be pulled into Parsable.
#TODO Naming.
#TODO API design? Keyword arguments for readability? Same applies to Factory
defmodule Parsable.Helpers do
  import Parsable.Factory

  #TODO Naming.
  def escape(source, target) do
    match source, _, do: target
  end

  def interspersed(content, separator) do
    match optional(interspersed!(content, separator)), result, do: (result || [])
  end

  def interspersed!(content, separator) do
    match [ content, many(tail_for(content, separator)) ],
          [ head,    tail                               ], do: [head | tail]
  end

  def separated(sequence, separator) do
    match Enum.intersperse(sequence, separator), result do
      Enum.take_every result, 2
    end
  end

  defp tail_for(content, separator) do
    match [ separator, content ],
          [ _,         result  ], do: result
  end

end

defmodule DerpyScript.Parser.Literals do
  import Parsable.Factory
  import Parsable.Helpers

  def integer do
    match ~r/(\d+)/, [digits] do
      {result, ""} = Integer.parse digits
      result
    end
  end

  def boolean do
    choice(
      escape("true",  true),
      escape("false", false)
    )
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

end

defmodule DerpyScript.Parser do
  import Parsable.Factory
  import Parsable.Helpers

  def script do
    many line
  end

  def line do
    choice(expression_line, empty_line, comment_line)
  end

  def empty_line do
    # TODO nil is also output of optional =>
    # should be possible to inline the *_line stuff so we have EOL in less places.
    match [space, "\n"], _, do: nil
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
    match ~r/( *)/, _, do: :space
  end

  def hardspace do
    match ~r/( +)/, _, do: :space
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
    match softwords([ bracket_list(identifier), "=>", expression ]),
                    [ arguments,                _,    body       ] do

      {:function, arguments, body}
    end
  end

  def assignment do
    match softwords([ identifier, choice("=", ":"), expression ]),
                    [ lhs,        _,                rhs        ] do

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
    import DerpyScript.Parser.Literals
    match choice(integer, string, boolean), value do
      {:literal, value}
    end
  end

  def invocation do
    match softwords([identifier,    bracket_list(expression) ]),
                    [function_name, arguments                ] do

      {:invocation, function_name, arguments }
    end
  end

  def recursion do
    match ["~", space, bracket_list(expression)],
          [_  , _,     result                  ], do: {:recursion, result}
  end

  def if_expression do
    match [words(["if", expression, "then", expression]), optional(else_clause)],
          [      [_,    condition,  _,      if_case,  ],  else_case            ] do
      { :if, condition, if_case, else_case }
    end
  end

  def else_clause do
    # Dirty little trick: Add leading empty string to force leading hardspace.
    match words(["", "else", expression]),
                [_,  _,      result    ], do: result
  end

  def block do
    block_start = ["do", space, "\n"]
    block_end   = [space, "end"]
    match [ block_start, many(prevent(block_end, line)), block_end ],
          [ _,           contents,                       _         ], do: contents
  end

  def infix_expression do
    infix_expression choice ~w(- + * <= >= < > && || /)
  end

  defp infix_expression(operator) do
    match softwords([ bare_expression, operator, expression]),
                    [ left,            op,       right     ], do: {:infix, op, left, right}
  end

  defp bracket_list(content) do
    match softwords([ "(", interspersed(content), ")" ]),
                    [ _,   inner,                 _,  ], do: inner
  end

  defp interspersed(content) do
    interspersed content, [space, ",", space]
  end

  defp words(of) do
    separated(of, hardspace)
  end

  defp softwords(of) do
    separated(of, space)
  end

end
