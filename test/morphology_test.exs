defmodule NN.MorpholyTest do
  use ExUnit.Case
  alias NN.Morphology

  require Record

  test "xor sensor record" do
    sensor = Morphology.sensor(:xor)

    assert Record.is_record(sensor, :sensor)
  end

  test "xor sensors record" do
    [sensor] = Morphology.sensors(:xor)

    assert Record.is_record(sensor, :sensor)
  end

  test "xor actuator record" do
    actuator = Morphology.actuator(:xor)

    assert Record.is_record(actuator, :actuator)
  end

  test "xor actuators record" do
    [actuator] = Morphology.actuators(:xor)

    assert Record.is_record(actuator, :actuator)
  end
end
