defmodule NN.SimpleCortexTest do
  use ExUnit.Case

  setup do
    env = self()

    {:ok, pid} = NN.SimpleCortex.start_link(env)

    [cortex: pid]
  end

  test "create cortex", %{cortex: cortex} do
    assert Process.alive?(cortex)
  end

  test "receive messages", %{cortex: cortex} do
    NN.SimpleCortex.sense_think_act(cortex)

    assert_receive {:"$gen_call", from, :sense}

    GenServer.reply from, [Random.uniform, Random.uniform]

    assert_receive {:"$gen_cast", {:act, [x]}}
    assert x >= -1
    assert x <= 1
  end

  test "stops cortex", %{cortex: cortex} do
    NN.SimpleCortex.stop(cortex)

    refute Process.alive?(cortex)
  end
end
