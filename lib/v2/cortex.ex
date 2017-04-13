defmodule NN.V2.Cortex do
  use GenServer

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      sensors: nil,
      actuators: nil,
      neurons: nil,
      total_steps: nil,
      memory: nil

  end
  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def handle_cast({exo_self, {id, sensors, actuators, neurons}, total_steps}, exo_self) do
    trigger_sensors(sensors)

    state = %State{
      exo_self: exo_self,
      id: id,
      sensors: sensors,
      actuators: actuators,
      neurons: neurons,
      total_steps: total_steps - 1,
      memory: actuators
    }

    {:noreply, state}
  end

  def handle_cast({actuator, :sync}, %{actuators: [actuator], total_steps: 0} = state) do

    {:stop, :normal, state}
  end

  def handle_cast({actuator, :sync}, %{actuators: [actuator]} = state) do
    %{sensors: sensors, memory: memory, total_steps: total_steps} = state

    trigger_sensors(sensors)

    state = %{state | actuators: memory, total_steps: total_steps - 1}

    {:noreply, state}
  end

  def handle_cast({actuator, :sync}, %{actuators: [actuator | actuators]} = state) do
    state = %{state | actuators: actuators}

    {:noreply, state}
  end

  def handle_cast({actuator, :sync}, state) do
    GenServer.cast(self(), {actuator, :sync})

    {:noreply, state}
  end

  def terminate(_reason, _state) do
    IO.puts "terminating"
  end

  defp trigger_sensors(sensors) do
    Enum.each(sensors, fn(s) ->
      GenServer.cast(s, {self(), :sync})
    end)
  end
end
