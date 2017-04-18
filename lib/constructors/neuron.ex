defmodule NN.Constructors.Neuron do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def create_neuro_layers(cortex_id, sensor, actuator, layer_densities) do
    input_idps = [{sensor(sensor, :id), sensor(sensor, :vector_length)}]
    total_layers = length(layer_densities)
    [first_layer_density | next_layer_densities] = layer_densities

    neuron_ids = generate_ids(first_layer_density, [])
      |> Enum.map(fn(id) -> {:neuron, {1, id}} end)

    state = %{
      cortex_id: cortex_id,
      actuator_id: actuator(actuator, :id),
      layer_index: 1,
      total_layers: total_layers,
      input_idps: input_idps,
      neuron_ids: neuron_ids,
      layer_densities: next_layer_densities,
      neurons: [],
      input_layer: nil,
      output_layer: nil
    }

    create_neuro_layers(state)
  end

  def create_neuro_layers(%{layer_densities: []} = state) do
    %{
      actuator_id: actuator_id,
      cortex_id: cortex_id,
      neurons: neurons,
      input_idps: input_idps,
      neuron_ids: neuron_ids,
      input_layer: input_layer
    } = state

    output_ids = [actuator_id]
    output_layer = create_neuro_layer(cortex_id, input_idps, neuron_ids, output_ids, [])
    neurons = Enum.reverse([output_layer | neurons])

    {input_layer, neurons, output_layer}
  end

  def create_neuro_layers(state) do
    %{
      cortex_id: cortex_id,
      layer_index: layer_index,
      input_idps: input_idps,
      neuron_ids: neuron_ids,
      layer_densities: [layer_density | next_layer_densities],
      neurons: neurons,
      input_layer: input_layer
    } = state

    ids = generate_ids(layer_density, [])
    output_neuron_ids = Enum.map(ids, fn(id) -> {:neuron, {layer_index+1, id}} end)
    layer_neurons = create_neuro_layer(cortex_id, input_idps, neuron_ids, output_neuron_ids, [])
    next_input_idps = Enum.map(neuron_ids, fn(id) -> {id, 1} end)

    create_neuro_layers(%{
      state |
      layer_index: layer_index + 1,
      input_idps: next_input_idps,
      neuron_ids: output_neuron_ids,
      layer_densities: next_layer_densities,
      neurons: [layer_neurons | neurons],
      input_layer: input_layer || layer_neurons
    })
  end

  def create_neuro_layer(cortex_id, input_idps, [id | neuron_ids], output_ids, acc) do
    neuron = create_neuron(input_idps, id, cortex_id, output_ids)
    create_neuro_layer(cortex_id, input_idps, neuron_ids, output_ids, [neuron|acc])
  end

  def create_neuro_layer(_cortex_id, _input_ids, [], _output_ids, acc) do
    acc
  end

  def create_neuron(input_idps, id, cortex_id, output_ids) do
    proper_input_idps = create_neural_input(input_idps, [])

    neuron(id: id,
      cortex_id: cortex_id,
      activation_function: :tanh,
      input_ids: proper_input_idps,
      output_ids: output_ids)
  end

  def create_neural_input([{input_id, input_vector_length}|input_idps], acc) do
    weights =  create_neural_weights(input_vector_length, [])
    create_neural_input(input_idps, [{input_id, weights}|acc])
  end

  def create_neural_input([], acc) do
    Enum.reverse([{:bias, Random.uniform - 0.5}|acc])
  end

  def create_neural_weights(0, acc) do
    acc
  end

  def create_neural_weights(index, acc) do
    w = Random.uniform - 0.5
    create_neural_weights(index-1, [w|acc])
  end
end
