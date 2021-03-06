defmodule NN.V3.Actuator do
  use GenServer
  alias NN.V3.Cortex

  defmodule State do
    defstruct exo_self: nil,
              id: nil,
              cortex: nil,
              actuator_type: nil,
              neurons: nil,
              memory: nil,
              signals: nil,
              scape: nil
  end

  def start_link(exo_self) do
    state = %State{exo_self: exo_self}

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def configure(pid, exo_self, id, cortex, scape, actuator_type, neurons) do
    GenServer.cast(pid, {exo_self, {id, cortex, scape, actuator_type, neurons}})
  end

  def forward(pid, from, signal) do
    GenServer.cast(pid, {from, :forward, signal})
  end

  def handle_cast(
        {exo_self, {id, cortex, scape, actuator_type, neurons}},
        %{exo_self: exo_self} = state
      ) do
    state = %{
      state
      | id: id,
        cortex: cortex,
        actuator_type: actuator_type,
        neurons: neurons,
        memory: neurons,
        signals: [],
        scape: scape
    }

    {:noreply, state}
  end

  def handle_cast({neuron, :forward, signal}, %{neurons: [neuron]} = state) do
    %{
      exo_self: exo_self,
      cortex: c,
      memory: neurons,
      signals: signals,
      actuator_type: type,
      scape: scape
    } = state

    {:fitness, fitness, halt_flag} = apply(__MODULE__, type, [signal ++ signals, scape, exo_self])

    trigger_cortex(c, fitness, halt_flag)

    state = %{state | neurons: neurons, signals: []}

    {:noreply, state}
  end

  def handle_cast(
        {neuron, :forward, signal},
        %{neurons: [neuron | neurons], signals: signals} = state
      ) do
    state = %{state | neurons: neurons, signals: signal ++ signals}

    {:noreply, state}
  end

  def handle_cast({neuron, :forward, signal}, state) do
    GenServer.cast(self(), {neuron, :forward, signal})

    {:noreply, state}
  end

  def trigger_cortex(cortex, fitness, halt_flag) do
    Cortex.sync(cortex, self(), fitness, halt_flag)
  end

  def send_output(output, scape, exo_self) do
    GenServer.call(scape, {exo_self, :action, Enum.reverse(output)})
  end
end
