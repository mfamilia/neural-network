defmodule NN.Constructors.SensorTest do
  alias NN.Constructors.Sensor
  require Record

  use ExUnit.Case

  test "create rng sensor record" do
    result = Sensor.create_sensor(:rng)

    assert Record.is_record(result, :sensor)
    assert {:sensor, {:sensor, _uuid}, Tuple, :rng, 2, List} = result
  end

  test "unsupported sensor type" do
    assert catch_exit(Sensor.create_sensor(:unsupported))
  end
end
