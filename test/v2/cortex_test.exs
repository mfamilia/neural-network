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
    {:ok, sensor} = Sensor.start_link
    {:ok, actuator} = Actuator.start_link
    {:ok, neuron} = Neuron.start_link
    total_steps = 3

    GenServer.cast(sut, {exo_self, {id, [sensor], [actuator], [neuron]}, total_steps})

    for _ <- 1..3 do
      GenServer.cast(sut, {actuator, :sync})
    end

    assert_receive {:EXIT, ^sensor, :normal}
    assert_receive {:EXIT, ^actuator, :normal}
    assert_receive {:EXIT, ^neuron, :normal}
    assert_receive {:EXIT, ^sut, :normal}
  end
end
