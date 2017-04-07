defmodule NN.SimpleSensorTest do
  use ExUnit.Case

  setup do
    neuron = env = self()

    {:ok, pid} = NN.SimpleSensor.start_link(neuron, env)

    [sensor: pid]
  end

  test "create sensor", %{sensor: sensor} do
    assert Process.alive?(sensor)
  end

  test "receive signal", %{sensor: sensor} do
    NN.SimpleSensor.sync(sensor)

    assert_receive {:"$gen_call", from, :sense}

    GenServer.reply from, [1, 2]

    assert_receive {:"$gen_cast", {:forward, [1, 2]}}
  end
end
