defmodule NN.SimpleActuator do
  use GenServer

  defmodule State do
    defstruct cortex: nil,
      env: nil
  end

  def start_link(cortex, env) do
    GenServer.start_link(__MODULE__, %State{cortex: cortex, env: env})
  end

  def act(pid, input) do
    GenServer.cast(pid, {:forward, input})
  end

  def handle_cast({:forward, input}, %{env: env} = state) do
    GenServer.cast env, {:act, input}

    {:noreply, state}
  end
end
