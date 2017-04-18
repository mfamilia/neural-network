defmodule NN.Constructors.Actuator do
  import NN.NetworkElementTypes
  import NN.Constructors.Ids

  def create_actuator(type) do
    case type do
      :print_results ->
        actuator(id: {:actuator, generate_id()}, type: :print_results, vector_length: 1)
      _ ->
        exit("System does not yet support an actuator by the type: #{type}.")
    end
  end
end
