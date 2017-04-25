defmodule NN.Handlers.GenotypeFile do
  use GenServer

  def start_link(file_name) do
    GenServer.start_link(__MODULE__, file_name)
  end

  def save(pid, genotype) do
    GenServer.cast(pid, {:save, genotype})
  end

  def load(pid) do
    GenServer.call(pid, :load)
  end

  def handle_cast({:save, genotype}, file_name) do
    {:ok, file} = File.open(file_name, [:write])
    Enum.each(genotype, fn(x) -> :io.format(file, "~p.~n", [x]) end)
    File.close(file)

    {:noreply, file_name}
  end

  def handle_call(:load, _from, file_name) do
    {:reply, :file.consult(file_name), file_name}
  end
end
