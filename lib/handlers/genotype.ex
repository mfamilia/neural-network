defmodule NN.Handlers.Genotype do
  use GenServer

  @io %{puts: &IO.puts/1}

  defmodule State do
    defstruct file_name: nil,
      store: nil,
      io: nil
  end

  def start_link(file_name, io \\ @io) do
    state = %State{
      file_name: String.to_atom(file_name),
      io: io
    }

    GenServer.start_link(__MODULE__, state)
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

  def save(pid, file_name \\ nil) do
    GenServer.cast(pid, {:save, file_name})
  end

  def update(pid, element) do
    GenServer.cast(pid, {:update, element})
  end

  def print(pid) do
    GenServer.cast(pid, :print)
  end

  def rename(pid, new_file_name) do
    GenServer.cast(pid, {:rename, new_file_name})
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

  def handle_cast({:save, nil}, %{file_name: f, store: s} = state) do
    :ets.tab2file(s, f)

    {:noreply, state}
  end

  def handle_cast({:save, f}, %{store: s} = state) do
    :ets.tab2file(s, String.to_atom(f))

    {:noreply, state}
  end

  def handle_cast({:update, element}, %{store: store} = state) do
    :ets.insert(store, element)

    {:noreply, state}
  end

  def handle_cast(:print, %{store: s, io: io} = state) do
    [
      get_cortex(s),
      get_elements(s, :sensor),
      get_elements(s, :neuron),
      get_elements(s, :actuator),
    ]
    |> List.flatten
    |> Enum.each(fn(e) ->
      io.puts.(inspect e)
    end)

    {:noreply, state}
  end

  def handle_cast({:rename, new_name}, state) do
    state = %{state |
      file_name: String.to_atom(new_name)
    }

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
