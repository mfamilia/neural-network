defmodule NN.V2.Neuron do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def backup(pid) do
    GenServer.call(pid, :backup)
  end

  def handle_call(:backup, _from, state) do
    {:reply, {self(), UUID.uuid4, []}, state}
  end
end
