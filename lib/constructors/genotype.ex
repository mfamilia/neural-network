defmodule NN.Constructors.Genotype do
  import NN.NetworkElementTypes
  import NN.Constructors.{
    Ids,
    Sensor,
    Actuator,
    Neuron,
    Cortex
  }

  use GenServer

  defmodule State do
    defstruct handler: nil,
      sensor_type: nil,
      actuator_type: nil,
      hidden_layer_densities: nil
  end

  def start_link(handler, sensor_type, actuator_type, hidden_layer_densities) do
    state = %State{
      handler: handler,
      sensor_type: sensor_type,
      actuator_type: actuator_type,
      hidden_layer_densities: hidden_layer_densities
    }

    GenServer.start_link(__MODULE__, state)
  end

  def construct_genotype(pid) do
    GenServer.cast(pid, :construct_genotype)
  end

  def handle_cast(:construct_genotype, state) do
    construct(state)

    {:noreply, state}
  end

  def construct(state) do
    %{handler: handler,
      sensor_type: st,
      actuator_type: at,
      hidden_layer_densities: hld} = state

    s = create_sensor(st)
    a = create_actuator(at)

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
    genotype = List.flatten([cortex, sensor, actuator | neurons])

    GenServer.cast(handler, {:save, genotype})
  end
end
