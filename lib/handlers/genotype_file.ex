defmodule NN.Handlers.GenotypeFile do
  use GenServer

  def start_link(file_name) do
    GenServer.start_link(__MODULE__, file_name)
  end

  def write_to_file(pid, genotype) do
    GenServer.cast(pid, {:genotype, genotype})
  end

  def handle_cast({:genotype, genotype}, file_name) do
    {:ok, file} = File.open(file_name, [:write])
    Enum.each(genotype, fn(x) -> :io.format(file, "~p~n", [x]) end)
    File.close(file)

    {:noreply, file_name}
  end
end
