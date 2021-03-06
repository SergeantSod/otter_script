#TODO Naming
defmodule OtterScript.Parser.Script do
  import Parsable.Factory
  import Parsable.Bling
  import OtterScript.Parser.Literals

  def script do
    many line
  end

  def line do
    match [ space, optional(choice(expression, comment)), space, "\n" ],
          [ _,     line_content,                          _,     _    ], do: line_content
  end

  def comment do
    match ["#", ~r/(.*)/ ],
          [_,   [content]], do: {:comment, content}
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
    import OtterScript.Parser.Literals
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
    infix_expression choice ~w(- + * <= >= == < > && || /)
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
