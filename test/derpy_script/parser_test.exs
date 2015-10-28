defmodule DerpyScript.ParserTest do
  use ExUnit.Case

  import Parsable.Core, only: [parse!: 2]
  import DerpyScript.Parser.Core

  defp assert_parse(parser, input, expected) when is_binary(input) do
    assert parse!(input, parser) == expected
  end

  defp assert_parse(parser, input, expected) when is_list(input) do
    Enum.each input, fn (i) ->
      assert_parse(parser, i, expected)
    end
  end

  test "parses integer literals" do
    assert_parse literal, "123456789",  { :literal,  123456789 }
    assert_parse literal, "-123456789", { :literal, -123456789 }
  end

  test "parses string literals" do
    assert_parse literal, ~S("abc\\\n"), {:literal, "abc\\\n"}
  end

  test "parses boolean literals" do
    assert_parse literal, "true",  { :literal,  true }
    assert_parse literal, "false", { :literal, false }
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
    some_block = "do
                    a=b
                    1234
                    true
                  end"
    assert_parse block,
      some_block, [
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
    assert_parse if_expression,
      "if true then do
        false
      end", {
        :if,
        {:literal, true},
        [ {:literal, false} ],
        nil
      }
  end

  test "parses an if expression with an else clause and a block" do
    assert_parse if_expression,
      "if true then do
        12
       end else do
        false
       end",
      {
        :if,
        {:literal, true},
        [ {:literal, 12} ],
        [ {:literal, false} ]
      }
  end

  test "third case for if" do
    assert_parse if_expression,
      "if true then 12 else do
          false
      end", {
        :if,
        {:literal, true},
        {:literal, 12},
        [ {:literal, false} ]
      }
  end

  test "parses a script" do
    some_script = ~S"""
                    print("Welcome to DerpyScript.")

                    # The fib function
                    fib:(x)=> do
                      if x <= 1 then 0 else do
                        ~(x - 1) + ~(x - 2)
                      end
                    end

                    print("Fib of 12:")
                    print(fib(12))
                    """
    assert_parse script,
      some_script,
      [
        {:invocation, "print", [literal: "Welcome to DerpyScript."]},
        nil,
        {:comment, " The fib function"},
        {:assignment, "fib",
          {:function, ["x"], [
            {:if,
              {:infix, "<=", {:reference, "x"}, {:literal, 1}},
              {:literal, 0},
              [
                {:infix, "+",
                  {:recursion, [{:infix, "-", {:reference, "x"}, {:literal, 1}}]},
                  {:recursion, [{:infix, "-", {:reference, "x"}, {:literal, 2}}]}
                }
              ]
            }
          ]}},
        nil,
        {:invocation, "print", [literal: "Fib of 12:"]},
        {:invocation, "print", [{:invocation, "fib", [literal: 12]}]}
      ]
  end
end
