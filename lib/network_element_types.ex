defmodule NN.NetworkElementTypes do
  require Record

  Record.defrecord :sensor, id: Tuple,
                            cortex_id: Tuple,
                            name: Atom,
                            vector_length: Integer,
                            fanned_out_ids: List

  Record.defrecord :actuator, id: Tuple,
                              cortex_id: Tuple,
                              name: Atom,
                              vector_length: Integer,
                              fanned_in_ids: List

  Record.defrecord :neuron, id: Tuple,
                            cortex_id: Tuple,
                            activation_function: Fun,
                            input_ids: List,
                            output_ids: List

  Record.defrecord :cortex, id: Tuple,
                            sensor_ids: List,
                            actuator_ids: List,
                            neuron_ids: List
end
