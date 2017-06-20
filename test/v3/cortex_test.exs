defmodule NN.V3.CortexTest do
  use ExUnit.Case
  alias NN.V3.{Cortex, Sensor, Actuator, Neuron}

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

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)

    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "sensor sync after actuator sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuator = exo_self
    actuators = [actuator]
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    fitness = 20
    halt = 0

    Cortex.sync(sut, actuator, fitness, halt)
    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "waits on halt sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuator = exo_self
    actuators = [actuator]
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    fitness = 20
    halt = 1

    Cortex.sync(sut, actuator, fitness, halt)
    refute_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "continues after halt", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuator = exo_self
    actuators = [actuator]
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    fitness = 20
    halt = 1

    Cortex.sync(sut, actuator, fitness, halt)
    refute_receive {:"$gen_cast", {^sut, :sync}}

    Cortex.reactivate(sut, exo_self)
    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "reactive only when halted", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuator = exo_self
    actuators = [actuator]
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    Cortex.reactivate(sut, exo_self)
    refute_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "send evalution report", %{sut: sut, exo_self: exo_self} do
    id = :id
    sensors = [exo_self]
    actuator = exo_self
    actuators = [actuator]
    neurons = []

    Cortex.configure(sut, exo_self, id, sensors, actuators, neurons)
    assert_receive {:"$gen_cast", {^sut, :sync}}

    fitness = 20
    halt = 1
    cycles = 1

    Cortex.sync(sut, actuator, fitness, halt)
    assert_receive {:"$gen_cast", {^sut, :evaluation_completed, ^fitness, ^cycles, _time_diff}}
  end

  test "terminates neural elements", %{sut: sut, exo_self: exo_self} do
    Process.flag :trap_exit, true
    id = :id
    {:ok, sensor} = Sensor.start_link(exo_self)
    scape = exo_self
    Sensor.configure(sensor, exo_self, id, sut, scape, :get_input, 2, [])
    {:ok, actuator1} = Actuator.start_link(exo_self)
    {:ok, actuator2} = Actuator.start_link(exo_self)
    {:ok, neuron} = Neuron.start_link(exo_self)
    Neuron.configure(neuron, exo_self, UUID.uuid4, sut, &:math.tanh/1, [], [])

    Cortex.configure(sut, exo_self, id, [sensor], [actuator1, actuator2], [neuron])

    assert_receive {:"$gen_call", from, {^exo_self, :sense}}
    GenServer.reply(from, {:percept, []})

    GenServer.stop(sut)

    assert_receive {:EXIT, ^sensor, :normal}
    assert_receive {:EXIT, ^actuator1, :normal}
    assert_receive {:EXIT, ^neuron, :normal}
    assert_receive {:EXIT, ^sut, :normal}
  end
end
