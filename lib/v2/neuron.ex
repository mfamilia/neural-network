defmodule NN.V2.Neuron do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end
end
