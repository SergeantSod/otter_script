#TODO Sync up naming with implementation
defmodule DerpyScript.RunnerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  import DerpyScript.Runner, only: [run: 1]

  test "evaluates integer literals" do
    assert 12 == run """
                     12
                     """

    assert -12== run """
                     -12
                     """
  end

  test "evaluates string literals" do
    assert "SomeString\n" == run """
                                 "SomeString\n"
                                 """
  end

  test "evaluates boolean literals" do
    assert true == run """
                       true
                       """

    assert false == run """
                        false
                        """
  end

  test "evaluates simple logical operations" do
    assert true == run """
                       not(false)
                       """

    assert false == run """
                        not(true)
                        """
  end

  test "evaluates if expressions without else clauses" do
    assert 12 == run """
                     if true then 12
                     """

    assert nil == run """
                      if false then 12
                      """
  end

  test "evaluates if expressions with else clauses" do
    assert 12 == run """
                     if true then 12 else 13
                     """

    assert 12 == run """
                     if false then 13 else 12
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

  test "evaluates higher-order functions" do
    assert 12 == run """
                     adding:(offset)=>do
                       # Look at my cool closure
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

  test "evaluates higher-order functions with inline function literals as last argument" do
    assert 12 == run """
                     replicate:(times,start,f)=>do
                       if times == 0 then do
                         start
                       end else do
                         f(~(times - 1, start, f))
                       end
                     end

                     #TODO This should have special syntax to prevent the horror that is javascript

                     replicate(2,8,(x)=>do
                       x + 2
                     end)
                     """
  end

  test "evaluates higher-order functions on built-in functions" do
    assert "1\n2\n3\n" == capture_io fn ->
      run """
          loop:(from, to, fun)=>do
            if from <= to then do
              fun(from)
              ~(from+1, to, fun)
            end
          end

          loop(1, 3, print)
          """
    end
  end
end
