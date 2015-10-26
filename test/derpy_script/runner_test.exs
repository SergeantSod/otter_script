defmodule DerpyScript.RunnerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  import DerpyScript.Runner, only: [run: 1]

  test "evaluates integer literals" do
    assert 12 == run """
                     12
                     """
  end

  test "evaluates string literals" do
    assert "SomeString\n" == run """
                                 "SomeString\n"
                                 """
  end

  test "evaluates assignments" do
    assert 12 == run """
                     a=12
                     a
                     """
  end

  test "evaluates simple print statements" do
    assert "Hello world.\n" == capture_io fn ->
      run """
          print("Hello world.")
          """
    end
  end

  test "evaluates simple arithmetic expressions" do
    assert 12 == run """
                     6 + 6
                     """

    assert 12 == run """
                     18 - 6
                     """

    assert 12 == run """
                     2 * 6
                     """

    assert 12 == run """
                     24 / 2
                     """
  end

  test "evaluates a function call" do
    assert 12 == run """
                     addition:(a,b)=> a + b
                     addition(6,6)
                     """
  end

  test "evaluates a recursive function" do
    assert 21 == run """
                     fib:(x)=> do
                       if x <= 1 then x else do
                         ~(x - 1) + ~(x - 2)
                       end
                     end
                     fib(8)
                     """
  end

  test "evaluates higher-level functions" do
    assert 12 == run """
                     adding:(offset)=>do
                       (x)=>do
                         offset + x
                       end
                     end

                     at_ten:(fun)=>do
                       fun(10)
                     end

                     at_ten(adding(2))
                     """
  end
end
