#!/bin/env elixir

defmodule Parsable do

  defmodule Factory do

    def many(of) do
      {:many, of}
    end

    def choice(a, b) do
      choice [a, b]
    end

    def choice(a, b, c) do
      choice [a, b, c]
    end

    def choice(of) when is_list(of) do
      {:choice, of}
    end

    def optional(of) do
      {:optional, of}
    end

    def transform(of, with) do
      {:transform, of, with}
    end

    defmacro transform(parser, match, do: block) do
      quote do
        transform unquote(parser), fn x ->
          unquote(match) = x
          unquote(block)
        end
      end
    end

  end

  defmacrop try_parse(do: do_clause, else: else_clause) do
    quote do
      try do
        unquote(do_clause)
      rescue
        MatchError -> unquote(else_clause)
        FunctionClauseError -> unquote(else_clause)
      end
    end
  end

  def parse!(source, spec) do
    {result, ""} = parse source, spec
    result
  end

  def parse(source, {:many, of}) do
    parse_into source, of, []
  end

  def parse(source, literal) when is_binary(literal) do
    { literal, strip_prefix!(literal, source) }
  end

  def parse(source, []), do: {[], source}

  def parse(source, [head_parse | rest_parse]) do
    { head_result,   rest }      = parse source, head_parse
    { other_results, real_rest } = parse rest, rest_parse
    { [ head_result | other_results ], real_rest }
  end


  def parse(source, {:choice, [first | rest]}) do
    try_parse do
      parse source, first
    else
      parse source, {:choice, rest}
    end
  end

  def parse(source, %Regex{}=pattern) do
    [first_match | match_groups] = Regex.run pattern, source
    { match_groups, strip_prefix!(first_match, source) }
  end

  def parse(source, {:optional, of}) do
    try_parse do
      parse source, of
    else
      {nil, source}
    end
  end

  def parse(source, {:transform, inner, transformation}) do
    { inner_result, rest } = parse source, inner
    { transformation.( inner_result ), rest }
  end

  defp parse_into(source, target, result) do
    try_parse do
      {single_result, rest} = parse source, target
      parse_into rest, target, [single_result | result]
    else
      {Enum.reverse(result), source}
    end
  end

  defp strip_prefix!(prefix, source) do
    { ^prefix, rest } = String.split_at source, String.length(prefix)
    rest
  end

end
