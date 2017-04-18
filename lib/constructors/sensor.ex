defmodule NN.Constructors.Sensor do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def create_sensor(type) do
    case type do
      :random ->
        sensor(id: {:sensor, generate_id()}, type: :random, vector_length: 2)
      _ ->
        exit("System does not yet support a sensor by the type: #{type}.")
    end
  end
end
