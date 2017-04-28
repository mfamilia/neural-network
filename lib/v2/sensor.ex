defmodule NN.V2.Sensor do
  use GenServer
  alias NN.V2.Neuron

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      cortex: nil,
      sensor_type: nil,
      vector_length: nil,
      neurons: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def sync(pid, cortex) do
    GenServer.cast(pid, {cortex, :sync})
  end

  def configure(pid, exo_self, id, cortex, sensor_type, vector_length, neurons) do
    GenServer.cast(pid, {exo_self, {id, cortex, sensor_type, vector_length, neurons}})
  end

  def handle_cast({exo_self, {id, cortex, sensor_type, vector_length, neurons}}, exo_self) do
    state = %State{
      exo_self: exo_self,
      id: id,
      cortex: cortex,
      sensor_type: sensor_type,
      vector_length: vector_length,
      neurons: neurons
    }

    {:noreply, state}
  end

  def handle_cast({cortex, :sync}, %{neurons: neurons, cortex: cortex} = state) do
    signal = sensory_vector(state)

    Enum.each(neurons, fn(n) ->
      Neuron.forward(n, self(), signal)
    end)

    {:noreply, state}
  end

  defp sensory_vector(%{vector_length: vl, sensor_type: type}) do
    apply(__MODULE__, type, [vl, []])
  end

  def random(0, acc) do
    acc
  end

  def random(vl, acc) do
    random(vl - 1, [Random.uniform | acc])
  end
end
