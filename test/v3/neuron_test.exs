defmodule NN.V3.NeuronTest do
  use ExUnit.Case, async: false
  alias NN.V3.Neuron

  import Mock

  setup do
    exo_self = self()
    {:ok, sut} = Neuron.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create neuron", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "get backup input weights", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    weights = [0, 1]
    input_weights = [{exo_self, weights}]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, input_weights, outputs)
    assert Neuron.input_weights(sut, cortex) == {sut, :id, input_weights}
  end

  test "backup and restore input weights", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    weights = [0.032, 0.453]
    input_weights = [{exo_self, weights, :test}]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, input_weights, outputs)

    Neuron.backup(sut, cortex)
    Neuron.perturb(sut, cortex)
    Neuron.restore(sut, cortex)

    assert Neuron.input_weights(sut, cortex) == {sut, :id, input_weights}
  end

  test "perturb input weights", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    weights = [0, 1]
    input_weights = [{exo_self, weights, :test}]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, input_weights, outputs)

    with_mock Random, uniform: fn -> 0 end do
      Neuron.perturb(sut, cortex)

      refute Neuron.input_weights(sut, cortex) == {sut, :id, input_weights}
    end
  end

  test "forwards signal to output", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    weights = [0, 1]
    inputs = [{exo_self, weights, :test}]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, inputs, outputs)

    Neuron.forward(sut, exo_self, [1, 2])

    assert_receive {:"$gen_cast", {^sut, :forward, [signal]}}
    assert is_number(signal)
  end

  test "forwards signal to output with bias", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    weights = [0, 1]
    inputs = [{exo_self, weights, :test} | [1]]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, inputs, outputs)

    Neuron.forward(sut, exo_self, [1, 2])

    assert_receive {:"$gen_cast", {^sut, :forward, [signal]}}
    assert is_number(signal)
  end

  test "forwards signal to output with multiple inputs", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    activation_function = :tanh
    {:ok, neuron1} = Neuron.start_link(exo_self)
    {:ok, neuron2} = Neuron.start_link(exo_self)
    inputs = [{exo_self, [1, 0], :test}, {neuron1, [1, 1], :neuron1}, {neuron2, [0, 0], :neuron2}]
    outputs = [exo_self]

    Neuron.configure(sut, exo_self, id, cortex, activation_function, inputs, outputs)

    Neuron.forward(sut, neuron2, [1, 2])
    refute_receive {:"$gen_cast", {_sut, :forward, _signal}}

    Neuron.forward(sut, neuron1, [1, 2])
    refute_receive {:"$gen_cast", {_sut, :forward, _signal}}

    Neuron.forward(sut, exo_self, [1, 2])

    assert_receive {:"$gen_cast", {^sut, :forward, [signal]}}
    assert is_number(signal)
  end
end
