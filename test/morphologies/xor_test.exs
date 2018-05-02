defmodule NN.Morphologies.XorTest do
  use ExUnit.Case
  alias NN.Morphologies.Xor

  import NN.NetworkElementTypes

  require Record

  test "sensors" do
    [sensor] = Xor.sensors

    assert Record.is_record(sensor, :sensor)
    assert {:sensor, _} = sensor(sensor, :id)
    assert sensor(sensor, :type) == :get_input
    assert sensor(sensor, :scape) == {:private, :xor}
    assert sensor(sensor, :vector_length) == 2
  end

  test "actuators" do
    [actuator] = Xor.actuators

    assert Record.is_record(actuator, :actuator)
    assert {:actuator, _} = actuator(actuator, :id)
    assert actuator(actuator, :type) == :send_output
    assert actuator(actuator, :scape) == {:private, :xor}
    assert actuator(actuator, :vector_length) == 1
  end
end
