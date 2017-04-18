defmodule NN.V2.ExoSelf do
  use GenServer
  import NN.NetworkElementTypes
  alias NN.V2.{Cortex, Sensor, Actuator, Neuron}

  defmodule State do
    defstruct file_name: nil,
      genotype: nil,
      store: nil
  end

  def start_link(file_name) do
    GenServer.start_link(__MODULE__, file_name)
  end

  def init(file_name) do
    {:ok, genotype} = :file.consult(file_name)
    store = :ets.new(:pid_store, [:set, :private])

    state = %State{
      file_name: file_name,
      genotype: genotype,
      store: store
    }

    map_neural_network(genotype, store)

    {:ok, state}
  end

  defp map_neural_network(genotype, store) do
    [cortex | cerebral_units] = genotype
    sensor_ids = cortex(cortex, :sensor_ids)
    actuator_ids = cortex(cortex, :actuator_ids)
    neuron_ids = cortex(cortex, :neuron_ids)
    cortex_id = cortex(cortex, :id)
    exo_self = self()

    start_network_elements(exo_self, store, Cortex, [cortex_id])
    start_network_elements(exo_self, store, Sensor, sensor_ids)
    start_network_elements(exo_self, store, Actuator, actuator_ids)
    start_network_elements(exo_self, store, Neuron, neuron_ids)
  end

  defp start_network_elements(exo_self, store, type, [id | ids]) do
    {:ok, element} = type.start_link(exo_self)
    :ets.insert(store, {id, element})
    :ets.insert(store, {element, id})

    start_network_elements(exo_self, store, type, ids)
  end

  defp start_network_elements(_exo_self, _store, _type, []) do
    true
  end
end
