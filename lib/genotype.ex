defmodule NN.Genotype do
  use GenServer

  defmodule State do
    defstruct store: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    store = :ets.new(:genotype, [:private, :set, {:keypos, 2}])

    state = %State{
      store: store
    }

    {:ok, state}
  end

  def cortex(pid) do
    GenServer.call(pid, :cortex)
  end

  def neurons(pid) do
    GenServer.call(pid, :neurons)
  end

  def neuron(pid, id) do
    GenServer.call(pid, {:neuron, id})
  end

  def sensors(pid) do
    GenServer.call(pid, :sensors)
  end

  def actuators(pid) do
    GenServer.call(pid, :actuators)
  end

  def element(pid, id) do
    GenServer.call(pid, {:element, id})
  end

  def update(pid, element) do
    GenServer.cast(pid, {:update, element})
  end

  def handle_call(:cortex, _from, %{store: store} = state) do
    {:reply, {:ok, get_cortex(store)}, state}
  end

  def handle_call(:neurons, _from, %{store: store} = state) do
    {:reply, {:ok, get_neurons(store)}, state}
  end

  def handle_call(:sensors, _from, %{store: store} = state) do
    {:reply, {:ok, get_elements(store, :sensor)}, state}
  end

  def handle_call(:actuators, _from, %{store: store} = state) do
    {:reply, {:ok, get_elements(store, :actuator)}, state}
  end

  def handle_call({:element, id}, _from, %{store: store} = state) do
    [element] = :ets.lookup(store, id)

    {:reply, {:ok, element}, state}
  end

  def handle_call({:element, id}, _from, %{store: store} = state) do
    [element] = :ets.lookup(store, id)

    {:reply, {:ok, element}, state}
  end

  def handle_cast({:update, element}, %{store: store} = state) do
    :ets.insert(store, element)

    {:noreply, state}
  end

  defp get_cortex(store) do
    [cortex] = :ets.match_object(store, {:cortex, :"_", :"_", :"_", :"_"})
    cortex
  end

  defp get_elements(store, key) do
   :ets.match_object(store, {key, :"_", :"_", :"_", :"_", :"_", :"_"})
  end

  defp get_neurons(store) do
   :ets.match_object(store, {:neuron, :"_", :"_", :"_", :"_", :"_"})
  end
end
