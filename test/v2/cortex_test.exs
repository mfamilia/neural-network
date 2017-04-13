defmodule NN.V2.CortexTest do
  use ExUnit.Case
  alias NN.V2.Cortex

  setup do
    exo_self = self()
    {:ok, sut} = Cortex.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create cortex", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "sensor sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuators = [exo_self]
    neurons = []
    total_steps = 10

    GenServer.cast(sut, {exo_self, {id, sensors, actuators, neurons}, total_steps})

    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "sensor sync after actuator sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuators = [exo_self]
    total_steps = 10
    neurons = []

    GenServer.cast(sut, {exo_self, {id, sensors, actuators, neurons}, total_steps})

    GenServer.cast(sut, {exo_self, :sync})

    assert_receive {:"$gen_cast", {^sut, :sync}}
    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "terminates after steps", %{sut: sut, exo_self: exo_self} do
    Process.flag :trap_exit, true
    id = :id
    sensors = [exo_self]
    actuators = [exo_self]
    neurons = []
    total_steps = 3

    GenServer.cast(sut, {exo_self, {id, sensors, actuators, neurons}, total_steps})

    for _ <- 1..3 do
      assert_receive {:"$gen_cast", {^sut, :sync}}
      GenServer.cast(sut, {exo_self, :sync})
    end

    assert_receive {:EXIT, ^sut, :normal}
  end
end
