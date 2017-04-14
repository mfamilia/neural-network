defmodule NN.V2.Sensor do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_cast({cortex, :sync}, state) do
    {:noreply, state}
  end
end
