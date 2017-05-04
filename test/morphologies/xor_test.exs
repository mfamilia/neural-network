defmodule NN.Morphologies.XORTest do
  use ExUnit.Case
  alias NN.Morphologies.XOR

  import NN.NetworkElementTypes

  require Record

  test "sensors" do
    [sensor] = XOR.sensors(:xor)

    assert Record.is_record(sensor, :sensor)
    assert {:sensor, _} = sensor(sensor, :id)
    assert sensor(sensor, :type) == :get_input
    assert sensor(sensor, :scape) == {:private, :xor_simulation}
    assert sensor(sensor, :vector_length) == 2
  end

  test "actuators" do
    [actuator] = XOR.actuators(:xor)

    assert Record.is_record(actuator, :actuator)
    assert {:actuator, _} = actuator(actuator, :id)
    assert actuator(actuator, :type) == :send_output
    assert actuator(actuator, :scape) == {:private, :xor_simulation}
    assert actuator(actuator, :vector_length) == 1
  end
end
