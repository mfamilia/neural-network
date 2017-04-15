defmodule NN.V2.SensorTest do
  use ExUnit.Case
  alias NN.V2.Sensor

  setup do
    exo_self = self()
    {:ok, sut} = Sensor.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create sensor", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "sensor sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = :cortex_id
    sensor_type = :random
    targets = [exo_self]
    vector_length = 2

    Sensor.initialize(sut, exo_self, id, cortex, sensor_type, vector_length, targets)

    Sensor.sync(sut, cortex)

    assert_receive {:"$gen_cast", {^sut, :forward, [x, y]}}
    assert is_number(x)
    assert is_number(y)
  end
end
