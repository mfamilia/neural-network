defmodule NN.Simple.SensorTest do
  use ExUnit.Case

  setup do
    neuron = env = self()

    {:ok, pid} = NN.Simple.Sensor.start_link(neuron, env)

    [sensor: pid]
  end

  test "create sensor", %{sensor: sensor} do
    assert Process.alive?(sensor)
  end

  test "receive signal", %{sensor: sensor} do
    NN.Simple.Sensor.sync(sensor)

    assert_receive {:"$gen_call", from, :sense}

    GenServer.reply from, [1, 2]

    assert_receive {:"$gen_cast", {:forward, [1, 2]}}
  end
end
