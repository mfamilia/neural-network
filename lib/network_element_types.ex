defmodule NN.NetworkElementTypes do
  require Record

  Record.defrecord :sensor,
    id: Tuple,
    cortex_id: Tuple,
    type: Atom,
    vector_length: Integer,
    neuron_ids: List

  Record.defrecord :actuator,
    id: Tuple,
    cortex_id: Tuple,
    type: Atom,
    vector_length: Integer,
    neuron_ids: List

  Record.defrecord :neuron,
    id: Tuple,
    cortex_id: Tuple,
    activation_function: Fun,
    #Need to rename this to input_id_weights
    input_ids: List,
    #Need to rename this to output_id_weights
    output_ids: List

  Record.defrecord :cortex,
    id: Tuple,
    sensor_ids: List,
    actuator_ids: List,
    neuron_ids: List
end
