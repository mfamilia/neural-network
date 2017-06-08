defmodule NN.V3.ActuatorTest do
  use ExUnit.Case
  alias NN.V3.{Actuator, Neuron}

  setup do
    exo_self = self()
    io = %{puts: fn(msg) -> send(exo_self, {:puts, msg}) end}
    {:ok, sut} = Actuator.start_link(exo_self, io)

    [sut: sut, exo_self: exo_self]
  end

  test "create actuator", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "cortex sync", %{sut: sut, exo_self: exo_self} do
    id = :id
    cortex = exo_self
    actuator_type = :send_output
    {:ok, neuron1} = Neuron.start_link(exo_self)
    {:ok, neuron2} = Neuron.start_link(exo_self)
    neurons = [neuron1, neuron2]
    scape = exo_self

    Actuator.configure(sut, exo_self, id, cortex, scape, actuator_type, neurons)

    output = [[1, 2], [3, 5]]

    Actuator.forward(sut, neuron2, List.first(output))
    Actuator.forward(sut, neuron1, List.last(output))

    assert_receive {:"$gen_call", from, {^sut, :action, ^output}}

    fitness = 80
    halt_flag = 1
    GenServer.reply(from, {fitness, halt_flag})

    assert_receive {:"$gen_cast", {^sut, :sync, ^fitness, ^halt_flag}}
  end
end