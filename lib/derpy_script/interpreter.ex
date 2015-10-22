defmodule DerpyScript.Interpreter do

  defmodule Function do
    @derive [Access]
    defstruct arguments: [], body: [], closure: %{}
  end

  defmodule State do
    @derive [Access]
    defstruct bindings: %{}, stack: [], core: nil
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
    {result, new_state} = evaluate(expression, state)
    new_state = put_in new_state, [:bindings, variable], result
    {result, new_state}
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
    if Map.has_key? state.bindings, variable_name do
      {state.bindings[variable_name], state}
    else
      raise "Variable #{variable_name} is undefined."
    end
  end

  def evaluate({:invocation, function_name, arguments}, state) do
    {evaluated_arguments, new_state} = evaluate_sequence arguments, state
     result = do_invoke(new_state, function_name, evaluated_arguments)
    {result, new_state}
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
    { left_result, state } = evaluate(left, state)
    { right_result, state } = evaluate(right, state)
    result = state.core.handle_infix operator, left_result, right_result
    {result, state}
  end

  def evaluate({:recursion, arguments}, state) do
    { left_result, state } = evaluate(left, state)
    { right_result, state } = evaluate(right, state)
    result = state.core.handle_infix operator, left_result, right_result
    {result, state}
  end

  def evaluate({:literal, value}, state), do: {value, state}
  def evaluate({:comment, _},     state), do: {nil,   state}
  def evaluate( nil,              state), do: {nil,   state}

  defp do_invoke(state, function, arguments) when is_binary(function) do
    if Map.has_key? state.bindings, function do
      do_invoke state, state.bindings[function], arguments
    else
      state.core.handle_function function, arguments
    end
  end

  defp do_invoke(state, %Function{}=function, arguments) do
    #TODO Raise error for arity
    new_bindings =
      function.arguments
        |> Enum.zip(arguments)
        |> Enum.into(function.closure)
    state_for_call = %State{ state |
      bindings: new_bindings,
      stack: [function | state.stack ]
    }
    {_, result} = evaluate(function.body, state_for_call)
    {result, state}
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
