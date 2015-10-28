defmodule Parsable.Core do

  alias Parsable.ParseError

  defmacrop try_parse(do: do_clause, else: else_clause) do
    quote do
      try do
        unquote(do_clause)
      rescue
        ParseError -> unquote(else_clause)
      end
    end
  end

  #TODO Maybe pull out this method onto top-level:
  # Parsable.parse
  def parse!(source, spec) do
    case parse(source, spec) do
      {result, ""} -> result
      {_,    rest} ->
        raise ParseError, at: rest
    end
  end

  def parse(source, {:lazy, parser_lambda}) do
    parse(source, parser_lambda.())
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

  def parse(source, {:choice, []}) do
    raise ParseError, at: source
  end

  def parse(source, {:choice, [first | rest]}) do
    try_parse do
      parse source, first
    else
      parse source, {:choice, rest}
    end
  end

  def parse(source, %Regex{}=spec) do
    case Regex.run(spec, source) do
      [first_match | match_groups] ->
        { match_groups, strip_prefix!(first_match, source) }
      _ ->
        raise ParseError, at: source
    end
  end

  def parse(source, {:optional, of}) do
    try_parse do
      parse source, of
    else
      {nil, source}
    end
  end

  def parse(source, {:match, inner, transformation}) do
    { inner_result, rest } = parse source, inner
    try do
      { transformation.( inner_result ), rest }
    rescue
      #TODO Does cathing multiple exceptions actually work like this in Elixir?
      _e in [MatchError, FunctionClauseError] ->
        raise ParseError, at: source
    end
  end

  def parse(source, {:check, condition, actual}) do
    parse(source, condition)
    parse(source, actual)
  end

  def parse(source, {:prevent, condition, actual}) do
    result = try_parse do
      {:prevent, parse(source, condition)}
    else
      {:pass , parse(source, actual)}
    end
    case result do
      {:prevent, _} ->
        raise ParseError, at: source
      {:pass, r } -> r
    end
  end

  def parse(source, _) do
    raise ParseError, at: source
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
    case String.split_at(source, String.length(prefix)) do
      { ^prefix, rest } -> rest
      _ -> raise ParseError, at: source
    end
  end

end
