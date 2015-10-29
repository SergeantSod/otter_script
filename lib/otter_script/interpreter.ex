defmodule OtterScript.Interpreter do

  defmodule ScriptError do
    defexception message: "Unknown script error."
  end

  defmodule CoreFunction do
    defstruct arity: 0, implementation: nil

    def invoke(function, state, arguments) do
      unless function.arity == length(arguments) do
        raise ScriptError, message: "Needs exactly #{function.arity} arguments."
      end
      function.implementation.(arguments, state)
    end

    def pure(arity, implementation) do
      %CoreFunction{
        arity: arity,
        implementation: fn (arguments, state) ->
          { apply(implementation, arguments), state }
        end
      }
    end

  end

  defmodule Function do
    import Enum
    defstruct arguments: [], body: [], closure: %{}

    def bind_arguments!(function, arguments) do
      unless length(function.arguments) == length(arguments) do
        raise ScriptError, message: "Needs exactly #{length(function.arguments)} arguments."
      end

      function.arguments
        |> zip(arguments)
        |> into(function.closure)
    end
  end

  defmodule State do
    import Map

    defstruct bindings: %{}, stack: []

    def bind_variable(state, name, value) do
      %{ state | bindings: put(state.bindings, name, value) }
    end

    def bound?(state, name) do
      has_key? state.bindings, name
    end

    def for_call(state, function, arguments) do
      %{
        state |
        bindings: Function.bind_arguments!(function, arguments),
        stack: [function | state.stack ]
      }
    end

    def core_function(state, name, arity, implementation) do
      bind_variable state, to_string(name), %CoreFunction{
        arity: arity,
        implementation: implementation
      }
    end

    def pure_core_function(state, name, arity, implementation) do
      bind_variable state, to_string(name), CoreFunction.pure(arity, implementation)
    end

  end


  def evaluate([], state) do
    {nil, state}
  end

  def evaluate([expression], state) do
    evaluate expression, state
  end

  def evaluate([expression | rest], state) do
    {_, new_state} = evaluate expression, state
    evaluate rest, new_state
  end

  def evaluate({:assignment, variable, expression}, state) do
    {result, state} = evaluate(expression, state)
    {result, State.bind_variable(state, variable, result)}
  end

  def evaluate({:function, arguments, body}, state) do
    {
      %Function{
        arguments: arguments,
        body: body,
        closure: state.bindings
      },
      state
    }
  end

  def evaluate({:reference, variable_name}, state) do
    if State.bound?(state, variable_name) do
      {state.bindings[variable_name], state}
    else
      raise ScriptError, message: "Variable #{variable_name} is undefined."
    end
  end

  def evaluate({:if, condition, if_case, else_case}, state) do
    {condition_result, state} = evaluate(condition, state)
    if condition_result do
      evaluate(if_case, state)
    else
      evaluate(else_case, state)
    end
  end

  def evaluate({:infix, operator, left, right}, state) do
    evaluate({:invocation, operator, [left, right]}, state)
  end

  def evaluate({:invocation, function_name, arguments}, state) do
    if State.bound?(state, function_name) do
      invoke state.bindings[function_name], arguments, state
    else
      raise ScriptError, message: "Function #{function_name} is undefined."
    end
  end

  def evaluate({:recursion, arguments}, state) do
    case state.stack do
      [current_function | _] ->
        invoke current_function, arguments, state
      _ ->
        raise ScriptError, message: "Cannot use recursion on top level."
    end
  end

  def evaluate({:literal, value}, state), do: {value, state}
  def evaluate({:comment, _},     state), do: {nil,   state}
  def evaluate( nil,              state), do: {nil,   state}

  defp invoke(function, arguments, state) do
    {evaluated_arguments, state} = evaluate_sequence arguments, state
    case function do
      %Function{} ->
        {result, _ } = evaluate function.body, State.for_call(state, function, evaluated_arguments)
        # Functions are pure in that they cannot directly affect the outer state.
        {result, state}
      %CoreFunction{} ->
        # Core Functions can modify the outer state.
        CoreFunction.invoke(function, state, evaluated_arguments)
    end
  end

  defp evaluate_sequence([], state) do
    {[], state}
  end

  defp evaluate_sequence([e | rest], state) do
    { result,                    new_state } = evaluate e, state
    { other_results,            last_state } = evaluate_sequence rest, new_state
    { [result | other_results], last_state }
  end

end
