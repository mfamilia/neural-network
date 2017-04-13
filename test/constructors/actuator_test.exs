defmodule NN.Constructors.ActuatorTest do
  alias NN.Constructors.Actuator
  require Record

  use ExUnit.Case

  test "create pts actuator record" do
    result = Actuator.create_actuator(:pts)

    assert Record.is_record(result, :actuator)
    assert {:actuator, {:actuator, _uuid}, Tuple, :pts, 1, List} = result
  end

  test "unsupported actuator type" do
    assert catch_exit(Actuator.create_actuator(:unsupported))
  end
end
