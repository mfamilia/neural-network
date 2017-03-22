defmodule NN.SimpleNeuronTest do
  use ExUnit.Case

  setup do
    weights = [0.5, 0.5, 0.5]
    {:ok, pid} = NN.SimpleNeuron.start_link(weights)

    [neuron: pid]
  end

  test "create neuron", %{neuron: neuron} do
    assert Process.alive?(neuron)
  end

  test "get weights", %{neuron: neuron} do
    weights = NN.SimpleNeuron.weights(neuron)

    assert ^weights = [0.5, 0.5, 0.5]
  end

  test "process sense", %{neuron: neuron} do
    signal = [1, 2]
    result = NN.SimpleNeuron.sense(neuron, signal)

    assert ^result = [0.9640275800758169]
  end

  test "random weights" do
    {:ok, pid} = NN.SimpleNeuron.start_link

    NN.SimpleNeuron.weights(pid)
      |> Enum.each(fn(x) ->
        assert x >= -0.5
        assert x <= 0.5
      end)
  end
end
