defmodule NN.Constructors.Actuator do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def create_actuator(name) do
    case name do
      :pts ->
        actuator(id: {:actuator, generate_id()}, name: :pts, vector_length: 1)
      _ ->
        exit("System does not yet support an actuator by the name: #{name}.")
    end
  end
end
