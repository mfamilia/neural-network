defmodule NN.Handlers.GenotypeFile do
  def load(file) do
    {:ok, store} = :ets.file2tab(file)
    elements = :ets.tab2list(store)

    {:ok, elements}
  end

  def save(file, elements) do
    store = :ets.new(file, [:private, :set, {:keypos, 2}])

    :ets.insert(store, elements)

    :ets.tab2file(store, file)

    :ok
  end
end
