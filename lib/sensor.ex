defmodule NN.Sensor do
  use GenServer

  def start_link(neuron) do
    GenServer.start_link(__MODULE__, neuron)
  end

  def sync(pid) do
    GenServer.cast(pid, :sync)
  end

  def handle_cast(:sync, neuron) do
    send neuron, {:forward, [:rand.uniform, :rand.uniform]}

    {:noreply, neuron}
  end
end
