defmodule NN.Morphologies.PrintTest do
  use ExUnit.Case
  alias NN.Morphologies.Print

  import NN.NetworkElementTypes

  require Record

  test "sensors" do
    [sensor] = Print.sensors

    assert Record.is_record(sensor, :sensor)
    assert {:sensor, _} = sensor(sensor, :id)
    assert sensor(sensor, :type) == :random
    assert sensor(sensor, :scape) == nil
    assert sensor(sensor, :vector_length) == 2
  end

  test "actuators" do
    [actuator] = Print.actuators

    assert Record.is_record(actuator, :actuator)
    assert {:actuator, _} = actuator(actuator, :id)
    assert actuator(actuator, :type) == :print_results
    assert actuator(actuator, :scape) == nil
    assert actuator(actuator, :vector_length) == 1
  end
end
