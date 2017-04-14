defmodule NN.V2.Actuator do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end
end
