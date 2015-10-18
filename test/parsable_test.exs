defmodule ParsableTest do
  use ExUnit.Case

  import Parsable, only: [parse!: 2]
  import Parsable.Factory


  defp assignment do
    match [ identifier, "=", choice(identifier, tuple), optional(choice(";", "\n")) ],
          [ left_hand,  _,    right_hand,                _] do
      {:assignment, left_hand, right_hand}
    end
  end

  defp identifier do
    match ~r/:(\w+):/, [x] do
      {:identifier, x}
    end
  end

  defp raw_tuple do
    ~r/<(\w+),(\w+)>/
  end

  defp tuple do
    match raw_tuple, [x,y] do
      {a, ""} = Integer.parse x
      {b, ""} = Integer.parse y
      {:tuple, a, b}
    end
  end

  defp tuple_list do
    match [tuple, optional([",", lazy(tuple_list)])],
          [head,  maybe_tail                       ]
          do
      case maybe_tail do
        nil ->
          [head]
        [_, tail] ->
          [head | tail]
      end
    end
  end

  test "accepts a string" do
    assert "foo" == parse! "foo", "foo"
  end

  test "rejects a string" do
    catch_error parse!("foo", "bar")
  end

  test "accepts a regexp" do
    assert ["a", "b"] == parse!("<a,b>", raw_tuple)
  end

  test "rejects a regexp" do
    catch_error parse!("aaa,a", raw_tuple)
  end

  test "accepts a transformation" do
    assert {:tuple, 12,13} == parse!("<12,13>", tuple)
  end

  test "accepts an optional value if it is present" do
    assert {:tuple, 12,13} == parse!("<12,13>", optional(tuple))
  end

  test "accepts an optional value if it is not present" do
    assert nil == parse!("", optional(tuple))
  end

  test "rejects an optional value" do
    catch_error parse!("derp", optional(tuple))
  end

  test "rejects a transformation" do
    catch_error parse!("<foo,bar>", tuple)
  end

  test "accepts one side of a choice" do
    assert {:tuple, 12,13} == parse!("<12,13>", choice [tuple, identifier])
  end

  test "accepts other side of a choice" do
    assert {:identifier, "name"} == parse!(":name:", choice [tuple, identifier])
  end

  test "accepts a sequence" do
    assert {:assignment, {:identifier, "foo"}, {:identifier, "bar"}} == parse!(":foo:=:bar:", assignment)
  end

  test "rejects a sequence" do
    catch_error parse!(":foo::bar:", assignment)
  end

  test "accepts via lookahead" do
    assert ["<1,2>"] == parse! "<1,2>", check(tuple,~r/(.+)/)
  end

  test "rejects via lookahead" do
    catch_error parse!("derp", check(tuple,~r/(.+)/))
  end

  test "accepts via negative lookahead" do
    assert ["derp"] == parse! "derp", prevent(tuple,~r/(.+)/)
  end

  test "reject via negative lookahead" do
    catch_error parse!("<1,2>", prevent(tuple,~r/(.+)/))
  end

  test "recursion via lazy" do
    assert [{:tuple, 12,13}] == parse!("<12,13>", tuple_list)
    assert [{:tuple, 12,13}, {:tuple, 1, 2}] == parse!("<12,13>,<1,2>", tuple_list)
  end

  test "should not use exceptions for control flow internally" do
    flunk "TODO"
  end

  test "accepts a repetition" do
    raw_expression = ~S"""
    :bar:=<12,13>
    :foo:=:bar:
    :blah:=<5,6>;:monkey:=:cheese:
    """
    assert parse!(raw_expression, many(assignment)) == [
      {:assignment, {:identifier, "bar"}, {:tuple, 12, 13}},
      {:assignment, {:identifier, "foo"}, {:identifier, "bar"}},
      {:assignment, {:identifier, "blah"}, {:tuple, 5, 6}},
      {:assignment, {:identifier, "monkey"}, {:identifier, "cheese"}}
    ]
  end
end
