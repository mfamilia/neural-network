defmodule NN.Morphology do
  import String

  def sensor(type) do
    List.first(sensors(type))
  end

  def sensors(type) do
    call_method(type, :sensors)
  end

  def actuator(type) do
    List.first(actuators(type))
  end

  def actuators(type) do
    call_method(type, :actuators)
  end

  def call_method(type, method) do
    morphology_type = to_string(type)
    module_name = "Elixir.NN.Morphologies.#{String.capitalize(morphology_type)}"
    module = to_existing_atom(module_name)

    apply(module, method, [])
  end
end
