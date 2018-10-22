defmodule NN.Constructors.NeuronTest do
  import NN.NetworkElementTypes
  alias NN.Constructors.Neuron

  use ExUnit.Case

  setup do
    cortex_id = {:cortex, UUID.uuid4()}
    sensor = sensor(id: {:sensor, UUID.uuid4()}, type: :random, vector_length: 2)
    actuator = actuator(id: {:actuator, UUID.uuid4()}, type: :print_results, vector_length: 1)
    layer_densities = [1, 3, 1]

    {
      input_layer,
      neurons,
      output_layer
    } =
      Neuron.create_neuro_layers(
        cortex_id,
        sensor,
        actuator,
        layer_densities
      )

    [
      input_layer: input_layer,
      neurons: neurons,
      output_layer: output_layer
    ]
  end

  test "input layer neurons", %{input_layer: i} do
    assert [{:neuron, id, cortex, :tanh, inputs, outputs}] = i
    assert {:neuron, {1, _uuid}} = id
    assert {:cortex, _uuid} = cortex
    assert [{sensor, weights}, {:bias, bias}] = inputs
    assert {:sensor, _uuid} = sensor

    Enum.each([bias | weights], fn x ->
      assert is_number(x)
    end)

    Enum.each(outputs, fn x ->
      assert {:neuron, {2, _uuid}} = x
    end)
  end

  test "neurons layers", %{neurons: neurons} do
    assert [layer1, layer2, layer3] = neurons
    assert length(layer1) == 1
    assert length(layer2) == 3
    assert length(layer3) == 1
  end

  test "output layer neurons", %{output_layer: o} do
    assert [{:neuron, id, cortex, :tanh, inputs, outputs}] = o
    assert {:neuron, {3, _uuid}} = id
    assert {:cortex, _uuid} = cortex
    assert [neuron1, neuron2, neuron3, {:bias, bias}] = inputs
    assert is_number(bias)

    Enum.each([neuron1, neuron2, neuron3], fn n ->
      assert {{:neuron, {2, _uuid}}, [weight]} = n
      assert is_number(weight)
    end)

    assert [{:actuator, _uuid}] = outputs
  end
end
