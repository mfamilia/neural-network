defmodule NN.V2.Cortex do
  use GenServer

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      sensors: nil,
      actuators: nil,
      neurons: nil,
      cycles: nil,
      memory: nil

  end
  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def handle_cast({exo_self, {id, sensors, actuators, neurons}, cycles}, exo_self) do
    trigger_sensors(sensors)

    state = %State{
      exo_self: exo_self,
      id: id,
      sensors: sensors,
      actuators: actuators,
      neurons: neurons,
      cycles: cycles - 1,
      memory: actuators
    }

    {:noreply, state}
  end

  def handle_cast({actuator, :sync}, %{actuators: [actuator], cycles: 0} = state) do
    {:stop, :normal, state}
  end

  def handle_cast({actuator, :sync}, %{actuators: [actuator]} = state) do
    %{sensors: sensors, memory: memory, cycles: cycles} = state

    trigger_sensors(sensors)

    state = %{state | actuators: memory, cycles: cycles - 1}

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

  def terminate(_reason, %{sensors: sensors, memory: actuators, neurons: neurons}) do
    [sensors, actuators, neurons]
      |> Enum.each(fn(x) ->
        Enum.each(x, &GenServer.stop/1)
      end)
  end

  defp trigger_sensors(sensors) do
    Enum.each(sensors, fn(s) ->
      GenServer.cast(s, {self(), :sync})
    end)
  end
end
