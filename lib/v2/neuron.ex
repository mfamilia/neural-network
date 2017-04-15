defmodule NN.V2.Neuron do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def backup(pid) do
    GenServer.call(pid, :backup)
  end

  def forward(pid, from, signal) do
    GenServer.cast(pid, {from, :forward, signal})
  end

  def handle_call(:backup, _from, state) do
    {:reply, {self(), UUID.uuid4, []}, state}
  end

  def handle_cast({from, :forward, signal}, state) do
    {:noreply, state}
  end
end
