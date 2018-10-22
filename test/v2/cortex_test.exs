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

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons, cycles)

    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "sensor sync after actuator sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuators = [exo_self]
    cycles = 10
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons, cycles)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    Cortex.sync(sut, exo_self)
    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "terminates after cycles", %{sut: sut, exo_self: exo_self} do
    Process.flag(:trap_exit, true)
    id = :id
    {:ok, sensor} = Sensor.start_link(exo_self)
    Sensor.configure(sensor, exo_self, id, sut, :random, 2, [])
    {:ok, actuator1} = Actuator.start_link(exo_self)
    {:ok, actuator2} = Actuator.start_link(exo_self)
    {:ok, neuron} = Neuron.start_link(exo_self)
    Neuron.configure(neuron, exo_self, UUID.uuid4(), sut, &:math.tanh/1, [], [])
    cycles = 3

    Cortex.configure(sut, exo_self, id, [sensor], [actuator1, actuator2], [neuron], cycles)

    for _ <- 1..3 do
      Cortex.sync(sut, actuator2)
      Cortex.sync(sut, actuator1)
    end

    assert_receive {:EXIT, ^sensor, :normal}
    assert_receive {:EXIT, ^actuator1, :normal}
    assert_receive {:EXIT, ^neuron, :normal}
    assert_receive {:EXIT, ^sut, :normal}
  end

  test "backup neurons", %{sut: sut, exo_self: exo_self} do
    Process.flag(:trap_exit, true)
    id = :id
    {:ok, sensor} = Sensor.start_link(exo_self)
    Sensor.configure(sensor, exo_self, id, sut, :random, 2, [])
    {:ok, actuator} = Actuator.start_link(exo_self)
    {:ok, neuron} = Neuron.start_link(exo_self)
    Neuron.configure(neuron, exo_self, UUID.uuid4(), sut, &:math.tanh/1, [], [])
    cycles = 3

    Cortex.configure(sut, exo_self, id, [sensor], [actuator], [neuron], cycles)

    for _ <- 1..3 do
      Cortex.sync(sut, actuator)
    end

    assert_receive {:"$gen_cast", {^sut, :backup, [{_uuid, []}]}}
  end
end
