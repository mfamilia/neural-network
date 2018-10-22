defmodule NN.NetworkElementTypes do
  require Record

  Record.defrecord(:sensor,
    id: Tuple,
    cortex_id: Tuple,
    type: Atom,
    vector_length: Integer,
    neuron_ids: List,
    scape: Atom
  )

  Record.defrecord(:actuator,
    id: Tuple,
    cortex_id: Tuple,
    type: Atom,
    vector_length: Integer,
    neuron_ids: List,
    scape: Atom
  )

  Record.defrecord(:neuron,
    id: Tuple,
    cortex_id: Tuple,
    activation_function: Fun,
    input_weights: List,
    output_ids: List
  )

  Record.defrecord(:cortex,
    id: Tuple,
    sensor_ids: List,
    actuator_ids: List,
    neuron_ids: List
  )
end
