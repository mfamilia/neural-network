defmodule NN.Handlers.GenotypeFile do
  use GenServer

  def start_link(file_name) do
    file_name = String.to_atom(file_name)
    GenServer.start_link(__MODULE__, file_name)
  end

  def save(pid, genotype) do
    GenServer.cast(pid, {:save, genotype})
  end

  def load(pid) do
    GenServer.call(pid, :load)
  end

  def read(pid, key, genotype) do
    GenServer.call(pid, {{:read, key}, genotype})
  end

  def handle_cast({:save, genotype}, file_name) do
    store = :ets.new(file_name, [:public, :set, {:keypos, 2}])

    Enum.each(genotype, fn(e) ->
      :ets.insert(store, e)
    end)

    :ets.tab2file(store, file_name)

    {:noreply, file_name}
  end

  def handle_call(:load, _from, file_name) do
    {:ok, store} = :ets.file2tab(file_name)
    {:reply, store, file_name}
  end

  def handle_call({{:read, key}, genotype}, _from, file_name) do
    [entry] = :ets.lookup(genotype, key)

    {:reply, entry, file_name}
  end
end
