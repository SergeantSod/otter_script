#TODO Naming.
#TODO API design? Keyword arguments for readability? Same applies to Factory
defmodule Parsable.Bling do

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
