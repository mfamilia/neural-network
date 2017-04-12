defmodule NN.Constructors.NeuronTest do
  import NN.NetworkElementTypes
  alias NN.Constructors.Neuron

  use ExUnit.Case

  setup do
    cortex_id = {:cortex, UUID.uuid4}
    sensor = sensor(id: {:sensor, UUID.uuid4}, name: :rng, vector_length: 2)
    actuator = actuator(id: {:actuator, UUID.uuid4}, name: :pts, vector_length: 1)
    layer_densities = [1, 3, 1]

    {
      input_layer,
      neurons,
      output_layer
    } = Neuron.create_neuro_layers(
      cortex_id,
      sensor,
      actuator,
      layer_densities
    )

    [
      input_layer: input_layer,
      neurons: neurons,
      output_layer: output_layer,
      layer_densities: layer_densities,
      cortex_id: cortex_id,
      sensor: sensor,
      actuator: actuator
    ]
  end

  test "input layer neurons", %{layer_densities: l, sensor: s, input_layer: i} do
    assert [{:neuron, id, cortex, af, inputs, outputs}] = i
    assert is_function(af, 1)
    expected_af = &:math.tanh/1
    assert expected_af == af
    assert {:neuron, {1, _uuid}} = id
    assert {:cortex, _uuid} = cortex
    assert [{sensor, weights}, {:bias, bias}] = inputs
    assert {:sensor, _uuid} = sensor

    Enum.each([bias | weights], fn(x) ->
      assert is_number(x)
    end)

    Enum.each(outputs, fn(x) ->
      assert {:neuron, {2, _uuid}} = x
    end)
  end

  test "output layer neurons", %{layer_densities: l, sensor: s, output_layer: o} do
    assert [{:neuron, id, cortex, af, inputs, outputs}] = o
    expected_af = &:math.tanh/1
    assert expected_af == af
    assert {:neuron, {3, _uuid}} = id
    assert {:cortex, _uuid} = cortex
    assert [neuron1, neuron2, neuron3, {:bias, bias}] = inputs
    assert is_number(bias)

    Enum.each([neuron1, neuron2, neuron3], fn(n) ->
      assert {{:neuron, {2, _uuid}}, [weight]} = n
      assert is_number(weight)
    end)

    assert [{:actuator, _uuid}] = outputs
  end
end
