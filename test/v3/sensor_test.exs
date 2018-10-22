defmodule NN.V3.SensorTest do
  use ExUnit.Case
  alias NN.V3.Sensor

  setup do
    exo_self = self()
    {:ok, sut} = Sensor.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create sensor", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "sensor get input sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = :cortex_id
    sensor_type = :get_input
    targets = [exo_self]
    vector_length = 2
    scape = exo_self

    Sensor.configure(sut, exo_self, id, cortex, scape, sensor_type, vector_length, targets)

    Sensor.sync(sut, cortex)

    assert_receive {:"$gen_call", from, {^exo_self, :sense}}
    GenServer.reply(from, {:percept, [0, 1]})

    assert_receive {:"$gen_cast", {^sut, :forward, [0, 1]}}
  end
end
