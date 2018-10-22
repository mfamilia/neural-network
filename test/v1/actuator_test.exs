defmodule NN.V1.ActuatorTest do
  use ExUnit.Case

  setup do
    cortex = env = self()

    {:ok, pid} = NN.V1.Actuator.start_link(cortex, env)

    [actuator: pid]
  end

  test "create actuator", %{actuator: actuator} do
    assert Process.alive?(actuator)
  end

  test "receive signal", %{actuator: actuator} do
    GenServer.cast(actuator, {:forward, [1, 2]})

    assert_receive {:"$gen_cast", {:act, [1, 2]}}
  end
end
