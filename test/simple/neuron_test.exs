defmodule NN.Simple.NeuronTest do
  use ExUnit.Case, async: false

  import Mock

  setup do
    target = self()

    {:ok, pid} = NN.Simple.Neuron.start_link(target)

    [neuron: pid]
  end

  test "create neuron", %{neuron: neuron} do
    assert Process.alive?(neuron)
  end

  test "sense output" do
    with_mock Random, [uniform: fn -> 1 end] do
      {:ok, neuron} = NN.Simple.Neuron.start_link(self())

      NN.Simple.Neuron.weights(neuron)
        |> Enum.each(fn(x) ->
          assert ^x = 0.5
        end)

      signal = [1, 2]
      NN.Simple.Neuron.sense(neuron, signal)

      assert_receive {:"$gen_cast", {:forward, [0.9640275800758169]}}
    end
  end

  test "random weights", %{neuron: neuron} do
    NN.Simple.Neuron.weights(neuron)
      |> Enum.each(fn(x) ->
        assert x >= -0.5
        assert x <= 0.5
      end)
  end
end