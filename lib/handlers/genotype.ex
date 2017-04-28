defmodule NN.Handlers.Genotype do
  use GenServer

  defmodule State do
    defstruct file_name: nil,
      store: nil
  end

  def start_link(file_name) do
    GenServer.start_link(__MODULE__, String.to_atom(file_name))
  end

  def init(file_name) do
    state = %State{
      file_name: file_name
    }

    {:ok, state}
  end

  def load(pid) do
    GenServer.call(pid, :load)
  end

  def new(pid) do
    GenServer.call(pid, :new)
  end

  def cortex(pid) do
    GenServer.call(pid, :cortex)
  end

  def neurons(pid) do
    GenServer.call(pid, :neurons)
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

  def save(pid) do
    GenServer.cast(pid, :save)
  end

  def update(pid, element) do
    GenServer.cast(pid, {:update, element})
  end

  def handle_call(:load, _from, %{file_name: f} = state) do
    {:ok, store} = :ets.file2tab(f)

    state = %{state |
      store: store
    }

    {:reply, :ok, state}
  end

  def handle_call(:new, _from, %{file_name: f} = state) do
    store = :ets.new(f, [:private, :set, {:keypos, 2}])

    state = %{state |
      store: store
    }

    {:reply, :ok, state}
  end

  def handle_call(:cortex, _from, %{store: store} = state) do
    {:reply, {:ok, get_cortex(store)}, state}
  end

  def handle_call(:neurons, _from, %{store: store} = state) do
    {:reply, {:ok, get_elements(store, :neuron)}, state}
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

  def handle_cast(:save, %{file_name: f, store: s} = state) do
    :ets.tab2file(s, f)

    {:noreply, state}
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
   :ets.match_object(store, {key, :"_", :"_", :"_", :"_", :"_"})
  end
end
