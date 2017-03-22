defmodule NN.SensorTest do
  use ExUnit.Case

  setup do
    neuron_pid = self()

    {:ok, pid} = NN.Sensor.start_link(neuron_pid)

    [sensor: pid]
  end

  test "create sensor", %{sensor: sensor} do
    assert Process.alive?(sensor)
  end

  test "receive signal", %{sensor: sensor} do
    NN.Sensor.sync(sensor)

    assert_receive {:forward, [_, _]}
  end
end
