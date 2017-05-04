defmodule NN.Constructors.Genotype do
  import NN.NetworkElementTypes
  import NN.Constructors.{
    Ids,
    Neuron,
    Cortex
  }

  alias NN.Morphology

  use GenServer

  defmodule State do
    defstruct handler: nil,
      sensor: nil,
      actuator: nil,
      hidden_layer_densities: nil
  end

  def start_link(handler, morphology, hidden_layer_densities) do
    state = %State{
      handler: handler,
      sensor: Morphology.sensor(morphology),
      actuator: Morphology.actuator(morphology),
      hidden_layer_densities: hidden_layer_densities
    }

    GenServer.start_link(__MODULE__, state)
  end

  def construct(pid) do
    GenServer.cast(pid, :construct)
  end

  def handle_cast(:construct, state) do
    construct_genotype(state)

    {:noreply, state}
  end

  defp construct_genotype(state) do
    %{handler: handler,
      sensor: s,
      actuator: a,
      hidden_layer_densities: hld} = state

    output_vector_length = actuator(a, :vector_length)
    layer_densities = List.insert_at(hld, -1, output_vector_length)

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
        GenServer.cast(handler, {:update, e})
      end)

    GenServer.cast(handler, :save)
  end
end
