defmodule NN.Constructors.Cortex do
  import NN.NetworkElementTypes

  def create_cortex(cortex_id, sensor_ids, actuator_ids, neuron_ids) do
    cortex(id: cortex_id, sensor_ids: sensor_ids, actuator_ids: actuator_ids, neuron_ids: neuron_ids)
  end
end
