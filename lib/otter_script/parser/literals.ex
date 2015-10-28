defmodule OtterScript.Parser.Literals do
  import Parsable.Factory
  import Parsable.Bling

  def integer do
    match ~r/(-?)(\d+)/, [negated, digits] do
      {result, ""} = Integer.parse digits
      case negated do
        ""  ->  result
        "-" -> -result
      end
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
