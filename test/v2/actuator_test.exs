defmodule NN.V2.ActuatorTest do
  use ExUnit.Case, async: false
  alias NN.V2.{Actuator, Neuron}

  import Mock

  setup do
    exo_self = self()
    {:ok, sut} = Actuator.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create sensor", %{sut: sut} do
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
    with_mock IO, [puts: fn(x) -> send exo_self, {:printed, x} end] do
      id = :id
      cortex = exo_self
      actuator_type = :print_results
      {:ok, neuron1} = Neuron.start_link
      {:ok, neuron2} = Neuron.start_link
      neurons = [neuron1, neuron2]

      Actuator.initialize(sut, exo_self, id, cortex, actuator_type, neurons)

      Actuator.forward(sut, neuron2, [1, 2])
      Actuator.forward(sut, neuron1, [3, 5])

      signals = [[3, 5], [1, 2]]
      printed = "Actuator signals: #{inspect signals}"
      assert_receive {:printed, ^printed}
    end
  end
end
