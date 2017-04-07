defmodule NN.Simple.Cortex do
  use GenServer

  defmodule State do
    defstruct sensor: nil,
      neuron: nil,
      actuator: nil,
      env: nil
  end

  def start_link(env) do
    GenServer.start_link(__MODULE__, %State{env: env})
  end

  def init(%{env: env} = state) do
    {:ok, actuator} = NN.Simple.Actuator.start_link(self(), env)
    {:ok, neuron} = NN.Simple.Neuron.start_link(actuator)
    {:ok, sensor} = NN.Simple.Sensor.start_link(neuron, env)

    {:ok, %{state | actuator: actuator, neuron: neuron, sensor: sensor}}
  end

  def sense_think_act(pid) do
    GenServer.cast(pid, :sense_think_act)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def terminate(_reason, %{neuron: n, sensor: s, actuator: a}) do
   [n, s, a]
     |> Enum.each(fn(x) ->
       GenServer.stop(x)
     end)
  end

  def handle_cast({:actuator, _actuator, :sync}, state) do
    {:noreply, state}
  end

  def handle_cast(:sense_think_act, %{sensor: sensor} = state) do
    NN.Simple.Sensor.sync(sensor)

    {:noreply, state}
  end
end
