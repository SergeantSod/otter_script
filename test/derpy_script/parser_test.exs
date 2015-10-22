defmodule DerpyScript.ParserTest do
  use ExUnit.Case

  import Parsable, only: [parse!: 2]
  import DerpyScript.Parser

  defp assert_parse(parser, input, expected) when is_binary(input) do
    assert parse!(input, parser) == expected
  end

  defp assert_parse(parser, input, expected) when is_list(input) do
    Enum.each input, fn (i) ->
      assert_parse(parser, i, expected)
    end
  end

  test "parses integer literals" do
    assert_parse literal, "123456789", {:literal, 123456789}
  end

  test "parses string literals" do
    assert_parse literal, ~S("abc\\\n"), {:literal, "abc\\\n"}
  end

  test "parses boolean literals" do
    assert_parse literal, "true",  {:literal, true}
    assert_parse literal, "false", {:literal, false}
  end

  test "parses an assignment" do
    assert_parse assignment, [
        "a=12",
        "a:12",
        "a= 12",
        "a :12",
        "a = 12",
        "a : 12"
      ],
      {:assignment, "a", {:literal, 12}}
  end

  test "parses a function literal" do
    assert_parse function, [
      "(a,b)=>123",
      "(a ,b )=> 123",
      "( a ,   b )  => 123",
      "( a ,   b)  =>123",
    ],{
      :function,
      ["a", "b"],
      {:literal, 123}
    }
  end

  test "parses an invocation" do
    assert_parse invocation, [
        "function(1,2,var)",
        "function( 1, 2, var)",
        "function ( 1, 2, var)"
      ], {
        :invocation,
        "function",
        [
          {:literal, 1},
          {:literal, 2},
          {:reference, "var"}
        ]
      }
  end

  test "parses a block" do
    some_block = "do\na=b\n1234\ntrue\nend"
    assert_parse block, some_block, [
      {:assignment, "a", {:reference, "b"}},
      {:literal, 1234},
      {:literal, true}
    ]
  end

  test "parses an if expression without else" do
    assert_parse if_expression, [
        "if 1 then true",
        "if 1  then  true",
      ], {
        :if,
        {:literal, 1},
        {:literal, true},
        nil
      }
  end

  test "parses an if expression with else clause" do
    assert_parse if_expression, [
        "if 1 then true else false",
        "if 1  then  true   else  false",
      ], {
        :if,
        {:literal, 1},
        {:literal, true},
        {:literal, false}
      }
  end

  test "parses an if expression without else clause and a block" do
    flunk "TODO"
  end

  test "parses an if expression with an else clause and a block" do
    flunk "TODO"
  end

  test "parses a script" do
    flunk "TODO"
  end
end
