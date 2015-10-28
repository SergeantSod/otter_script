defmodule Parsable.Factory do

  def many(of) do
    {:many, of}
  end

  def choice(a, b) do
    choice [a, b]
  end

  def choice(a, b, c) do
    choice [a, b, c]
  end

  def choice(a, b, c, d) do
    choice [a, b, c, d]
  end

  def choice(a, b, c, d, e) do
    choice [a, b, c, d, e]
  end

  def choice(of) when is_list(of) do
    {:choice, of}
  end

  def optional(of) do
    {:optional, of}
  end

  #TODO Naming
  def match(of, with) do
    {:match, of, with}
  end

  #TODO Naming
  def check(condition, actual) do
    {:check, condition, actual}
  end

  #TODO Naming
  def prevent(condition, actual) do
    {:prevent, condition, actual}
  end

  defmacro lazy(parser_expression) do
    quote do
      {:lazy, fn -> unquote(parser_expression) end}
    end
  end

  #TODO Naming
  defmacro match(parser, match, do: block) do
    quote do
      match unquote(parser), fn x ->
        unquote(match) = x
        unquote(block)
      end
    end
  end

end
