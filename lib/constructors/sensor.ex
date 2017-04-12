defmodule NN.Constructors.Sensor do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def create_sensor(name) do
    case name do
      :rng ->
        sensor(id: {:sensor, generate_id()}, name: :rng, vector_length: 2)
      _ ->
        exit("System does not yet support a sensor by the name: #{name}.")
    end
  end
end
