defmodule NN.V2.ActuatorTest do
  use ExUnit.Case
  alias NN.V2.{Actuator, Neuron}

  setup do
    exo_self = self()
    io = %{puts: fn(msg) -> send(exo_self, {:puts, msg}) end}
    {:ok, sut} = Actuator.start_link(exo_self, io)

    [sut: sut, exo_self: exo_self]
  end

  test "create actuator", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "cortex sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    actuator_type = :print_results
    neurons = [exo_self]

    Actuator.initialize(sut, exo_self, id, cortex, actuator_type, neurons)

    Actuator.forward(sut, exo_self, [1, 2])

    assert_receive {:"$gen_cast", {^sut, :sync}}
  end

  test "print results", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    actuator_type = :print_results
    {:ok, neuron1} = Neuron.start_link(exo_self)
    {:ok, neuron2} = Neuron.start_link(exo_self)
    neurons = [neuron1, neuron2]

    Actuator.initialize(sut, exo_self, id, cortex, actuator_type, neurons)

    Actuator.forward(sut, neuron2, [1, 2])
    Actuator.forward(sut, neuron1, [3, 5])

    signals = [[3, 5], [1, 2]]
    printed = "Actuator signals: #{inspect signals}"
    assert_receive {:puts, ^printed}, 2_000
  end
end
