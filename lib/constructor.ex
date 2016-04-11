defmodule NN.Constructor do
  import NN.NetworkElementTypes

  def construct_genotype(sensor_name, actuator_name, hidden_layer_densities) do
    construct_genotype(:feed_forward_nn, sensor_name, actuator_name, hidden_layer_densities)
  end

  def construct_genotype(file_name, sensor_name, actuator_name, hidden_layer_densities) do
    s = create_sensor(sensor_name)
    a = create_actuator(actuator_name)
    output_vector_length = actuator(a, :vector_length)
    layer_densities = List.insert_at(hidden_layer_densities, -1, output_vector_length)
    cortex_id = {:cortex, generate_id()}

    neurons = create_neuro_layers(cortex_id, s, a, layer_densities)
    input_layer = List.first(neurons)
    output_layer = List.last(neurons)
    first_layer_neuron_ids = Enum.map(input_layer, fn(n) -> neuron(n, :id) end)
    last_layer_neuron_ids = Enum.map(output_layer, fn(n) -> neuron(n, :id) end)
    neuron_ids = Enum.map(List.flatten(neurons), fn(n) -> neuron(n, :id) end)
    sensor = sensor(s, cortex_id: cortex_id, fanned_out_ids: first_layer_neuron_ids)
    actuator = actuator(a, cortex_id: cortex_id, fanned_in_ids: last_layer_neuron_ids)
    cortex = create_cortex(cortex_id, [sensor(s, :id)], [actuator(a, :id)], neuron_ids)
    genotype = List.flatten([cortex, sensor, actuator|neurons])
    {:ok, file} = File.open(file_name, [:write])
    Enum.each(genotype, fn(x) -> :io.format(file, "~p~n", [x]) end)
    File.close(file)
  end

  def create_sensor(name) do
    case name do
      :rng ->
        sensor(id: {:sensor, generate_id()}, name: :rng, vector_length: 2)
      _ ->
        exit("System does not yet support a sensor by the name: #{name}.")
    end
  end

  def create_actuator(name) do
    case name do
      :pts ->
        actuator(id: {:actuator, generate_id()}, name: :pts, vector_length: 1)
      _ ->
        exit("System does not yet support an actuator by the name: #{name}.")
    end
  end

  def create_neuro_layers(cortex_id, sensor, actuator, layer_densities) do
    input_idps = [{sensor(sensor, :id), sensor(sensor, :vector_length)}]
    total_layers = length(layer_densities)
    [first_layer_density|next_layer_densities] = layer_densities
    ids = generate_ids(first_layer_density, [])
    neuron_ids = Enum.map(ids, fn(id) -> {:neuron, {1, id}} end)
    create_neuro_layers(cortex_id, actuator(actuator, :id), 1, total_layers, input_idps, neuron_ids, next_layer_densities, [])
  end

  def create_neuro_layers(cortex_id, actuator_id, layer_index, total_layers, input_idps, neuron_ids, [layer_density|next_layer_densities], acc) do
    ids = generate_ids(layer_density, [])
    output_neuron_ids = Enum.map(ids, fn(id) -> {:neuron, {layer_index+1, id}} end)
    layer_neurons = create_neuro_layer(cortex_id, input_idps, neuron_ids, output_neuron_ids, [])
    next_input_idps = Enum.map(neuron_ids, fn(id) -> {id, 1} end)
    create_neuro_layers(cortex_id, actuator_id, layer_index+1, total_layers, next_input_idps, output_neuron_ids, next_layer_densities, [layer_neurons|acc])
  end

  def create_neuro_layers(cortex_id, actuator_id, total_layers, total_layers, input_idps, neuron_ids, [], acc) do
    output_ids = [actuator_id]
    layer_neurons = create_neuro_layer(cortex_id, input_idps, neuron_ids, output_ids, [])
    Enum.reverse([layer_neurons|acc])
  end

  def create_neuro_layer(cortex_id, input_idps, [id|neuron_ids], output_ids, acc) do
    neuron = create_neuron(input_idps, id, cortex_id, output_ids)
    create_neuro_layer(cortex_id, input_idps, neuron_ids, output_ids, [neuron|acc])
  end

  def create_neuro_layer(_cortex_id, _input_ids, [], _output_ids, acc) do
    acc
  end

  def create_neuron(input_idps, id, cortex_id, output_ids) do
    proper_input_idps = create_neural_input(input_idps, [])
    neuron(id: id, cortex_id: cortex_id, activation_function: &:math.tanh(&1), input_ids: proper_input_idps, output_ids: output_ids)
  end

  def create_neural_input([{input_id, input_vector_length}|input_idps], acc) do
    weights =  create_neural_weights(input_vector_length, [])
    create_neural_input(input_idps, [{input_id, weights}|acc])
  end

  def create_neural_input([], acc) do
    Enum.reverse([{:bias, :random.uniform - 0.5}|acc])
  end

  def create_neural_weights(0, acc) do
    acc
  end

  def create_neural_weights(index, acc) do
    w = :random.uniform - 0.5
    create_neural_weights(index-1, [w|acc])
  end

  def generate_ids(0, acc) do
    acc
  end

  def generate_ids(index, acc) do
    id = generate_id()
    generate_ids(index-1, [id|acc])
  end

  def generate_id do
    UUID.uuid4()
  end

  def create_cortex(cortex_id, sensor_ids, actuator_ids, neuron_ids) do
    cortex(id: cortex_id, sensor_ids: sensor_ids, actuator_ids: actuator_ids, neuron_ids: neuron_ids)
  end
end
