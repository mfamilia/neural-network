defmodule NN.V3.Sensor do
  use GenServer
  alias NN.V3.Neuron

  defmodule State do
    defstruct exo_self: nil,
              id: nil,
              cortex: nil,
              scape: nil,
              sensor_type: nil,
              vector_length: nil,
              neurons: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def init(state) do
    {:ok, state}
  end

  def sync(pid, cortex) do
    GenServer.cast(pid, {cortex, :sync})
  end

  def configure(pid, exo_self, id, cortex, scape, sensor_type, vector_length, neurons) do
    GenServer.cast(pid, {exo_self, {id, cortex, scape, sensor_type, vector_length, neurons}})
  end

  def handle_cast({exo_self, {id, cortex, scape, sensor_type, vector_length, neurons}}, exo_self) do
    state = %State{
      exo_self: exo_self,
      id: id,
      cortex: cortex,
      scape: scape,
      sensor_type: sensor_type,
      vector_length: vector_length,
      neurons: neurons
    }

    {:noreply, state}
  end

  def handle_cast({cortex, :sync}, %{cortex: cortex} = state) do
    signal = sensory_vector(state)

    %{neurons: neurons} = state

    Enum.each(neurons, fn n ->
      Neuron.forward(n, self(), signal)
    end)

    {:noreply, state}
  end

  defp sensory_vector(state) do
    %{
      vector_length: vl,
      scape: scape,
      sensor_type: type,
      exo_self: exo_self
    } = state

    apply(__MODULE__, type, [vl, scape, exo_self])
  end

  def get_input(_vl, scape, exo_self) do
    {:percept, data} = GenServer.call(scape, {exo_self, :sense})

    data
  end
end
