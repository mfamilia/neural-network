defmodule NN.V2.Actuator do
  use GenServer
  alias NN.V2.Cortex

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      cortex: nil,
      actuator_type: nil,
      neurons: nil,
      memory: nil,
      signals: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def initialize(pid, exo_self, id, cortex, actuator_type, neurons) do
    GenServer.cast(pid, {exo_self, {id, cortex, actuator_type, neurons}})
  end

  def forward(pid, from, signal) do
    GenServer.cast(pid, {from, :forward, signal})
  end

  def handle_cast({exo_self, {id, cortex, actuator_type, neurons}}, exo_self) do
    state = %State{
      exo_self: exo_self,
      id: id,
      cortex: cortex,
      actuator_type: actuator_type,
      neurons: neurons,
      memory: neurons,
      signals: []
    }

    {:noreply, state}
  end

  def handle_cast({neuron, :forward, signal}, %{neurons: [neuron]} = state) do
    %{
      cortex: c,
      memory: neurons,
      signals: signals,
      actuator_type: type
    } = state

    trigger_cortex(c)
    apply(__MODULE__, type, [[signal | signals]])

    state = %{state | neurons: neurons, signals: []}

    {:noreply, state}
  end

  def handle_cast({neuron, :forward, signal}, %{neurons: [neuron | neurons], signals: signals} = state) do
    state = %{state | neurons: neurons, signals: [signal | signals]}

    {:noreply, state}
  end

  def handle_cast({neuron, :forward, signal}, state) do
    GenServer.cast(self(), {neuron, :forward, signal})

    {:noreply, state}
  end

  def trigger_cortex(cortex) do
    Cortex.sync(cortex, self())
  end

  def print_results(results) do
    reversed_results = Enum.reverse(results)

    IO.puts "Actuator signals: #{inspect reversed_results}"
  end
end
