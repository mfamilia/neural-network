defmodule NN.Constructors.CortexTest do
  import NN.NetworkElementTypes
  alias NN.Constructors.Cortex
  require Record

  use ExUnit.Case

  test "create cortex record" do
    cortex_id = {:cortex_id}
    sensor_ids = [{:sensor_id}]
    actuator_ids = [{:actuator_id}]
    neuron_ids = [{:neuron_id}]

    result = Cortex.create_cortex(cortex_id, sensor_ids, actuator_ids, neuron_ids)

    assert Record.is_record(result, :cortex)
    assert {:cortex, ^cortex_id, ^sensor_ids, ^actuator_ids, ^neuron_ids} = result
  end
end
