defmodule NN.V2.CortexTest do
  use ExUnit.Case
  alias NN.V2.{Cortex, Sensor, Actuator, Neuron}

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
    cycles = 10

    GenServer.cast(sut, {exo_self, {id, sensors, actuators, neurons}, cycles})

    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "sensor sync after actuator sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuators = [exo_self]
    cycles = 10
    neurons = []

    GenServer.cast(sut, {exo_self, {id, sensors, actuators, neurons}, cycles})

    GenServer.cast(sut, {exo_self, :sync})

    assert_receive {:"$gen_cast", {^sut, :sync}}
    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "terminates after cycles", %{sut: sut, exo_self: exo_self} do
    Process.flag :trap_exit, true
    id = :id
    {:ok, sensor} = Sensor.start_link
    {:ok, actuator1} = Actuator.start_link
    {:ok, actuator2} = Actuator.start_link
    {:ok, neuron} = Neuron.start_link
    cycles = 3

    GenServer.cast(sut, {exo_self, {id, [sensor], [actuator1, actuator2], [neuron]}, cycles})

    for _ <- 1..3 do
      GenServer.cast(sut, {actuator2, :sync})
      GenServer.cast(sut, {actuator1, :sync})
    end

    assert_receive {:EXIT, ^sensor, :normal}
    assert_receive {:EXIT, ^actuator1, :normal}
    assert_receive {:EXIT, ^neuron, :normal}
    assert_receive {:EXIT, ^sut, :normal}
  end
end
