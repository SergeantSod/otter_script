defmodule Parsable.ParseError do

  defexception at: ""

  def message(parse_error) do
    ~s"""
    Failed to parse at or near:
    #{at_message parse_error.at}
    """
  end

  defp at_message(at) do
    at |> String.split("\n")
       |> ellipsize_lines
       |> indent_lines
       |> Enum.join("\n")
  end

  defp indent_lines(lines) do
    Enum.map lines, fn l ->
      "   #{l}"
    end
  end

  defp ellipsize_lines(lines) do
    if Enum.count(lines) > 4 do
      Enum.take(lines, 3) ++ ["..."]
    else
      lines
    end
  end

end
