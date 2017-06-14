defmodule NN.Morphologies.Print do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def sensors do
    [
      sensor(id: {:sensor, generate_id()}, type: :random, scape: nil, vector_length: 2)
    ]
  end

  def actuators do
    [
      actuator(id: {:actuator, generate_id()}, type: :print_results, scape: nil, vector_length: 1)
    ]
  end
end
