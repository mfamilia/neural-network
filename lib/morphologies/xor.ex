defmodule NN.Morphologies.XOR do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def sensors(:xor) do
    [
      sensor(id: {:sensor, generate_id()}, type: :get_input, scape: {:private, :xor_simulation}, vector_length: 2)
    ]
  end

  def actuators(:xor) do
    [
      actuator(id: {:actuator, generate_id()}, type: :send_output, scape: {:private, :xor_simulation}, vector_length: 1)
    ]
  end
end
