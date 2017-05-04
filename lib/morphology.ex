defmodule NN.Morphology do
  import NN.Morphologies.XOR

  def sensor(type) do
    sensors(type)
    |> List.first
  end

  def actuator(type) do
    actuators(type)
    |> List.first
  end
end
