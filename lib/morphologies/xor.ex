defmodule NN.Morphologies.Xor do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def sensors do
    [
      sensor(
        id: {:sensor, generate_id()},
        type: :get_input,
        scape: {:private, :xor},
        vector_length: 2
      )
    ]
  end

  def actuators do
    [
      actuator(
        id: {:actuator, generate_id()},
        type: :send_output,
        scape: {:private, :xor},
        vector_length: 1
      )
    ]
  end
end
