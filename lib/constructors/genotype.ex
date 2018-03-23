defmodule NN.Constructors.Genotype do
  import NN.NetworkElementTypes
  import NN.Constructors.{
    Ids,
    Neuron,
    Cortex
  }

  alias NN.Genotype

  alias NN.Morphology

  def construct(morphology, hidden_layer_densities) do
    s = Morphology.sensor(morphology)
    a = Morphology.actuator(morphology)
    {:ok, genotype} = Genotype.start_link

    Random.seed()

    output_vector_length = actuator(a, :vector_length)
    layer_densities = List.insert_at(hidden_layer_densities, -1, output_vector_length)
    cortex_id = {:cortex, generate_id()}

    {input_layer, neurons, output_layer} = create_neuro_layers(cortex_id, s, a, layer_densities)

    first_layer_neuron_ids = Enum.map(input_layer, fn(n) -> neuron(n, :id) end)
    last_layer_neuron_ids = Enum.map(output_layer, fn(n) -> neuron(n, :id) end)

    neuron_ids = neurons
      |> List.flatten
      |> Enum.map(fn(n) ->
        neuron(n, :id)
      end)

    sensor = sensor(s, cortex_id: cortex_id, neuron_ids: first_layer_neuron_ids)
    actuator = actuator(a, cortex_id: cortex_id, neuron_ids: last_layer_neuron_ids)
    cortex = create_cortex(cortex_id, [sensor(s, :id)], [actuator(a, :id)], neuron_ids)

    List.flatten([cortex, sensor, actuator | neurons])
      |> Enum.each(fn(e) ->
        Genotype.update(genotype, e)
      end)

    {:ok, genotype}
  end
end
