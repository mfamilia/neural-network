defmodule NN.V3.Cortex do
  use GenServer
  alias NN.V3.{Sensor}

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      sensors: nil,
      actuators: nil,
      neurons: nil,
      cycles: nil,
      memory: nil,
      start_time: nil,
      fitness: nil,
      status: nil,
      halts: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def configure(pid, exo_self, id, sensors, actuators, neurons) do
    GenServer.cast(pid, {exo_self, {id, sensors, actuators, neurons}})
  end

  def sync(pid, from, fitness, halt) do
    GenServer.cast(pid, {from, :sync, fitness, halt})
  end

  def reactivate(pid, exo_self) do
    GenServer.cast(pid, {:reactivate, exo_self})
  end

  def handle_cast({exo_self, {id, sensors, actuators, neurons}}, exo_self) do
    trigger_sensors(sensors)

    state = %State{
      exo_self: exo_self,
      id: id,
      sensors: sensors,
      actuators: actuators,
      neurons: neurons,
      cycles: 1,
      memory: actuators,
      start_time: now(),
      fitness: 0,
      status: :active,
      halts: 0
    }

    {:noreply, state}
  end

  def handle_cast({actuator, :sync, fitness, halt}, %{actuators: [actuator], halts: h} = state)
    when h + halt > 0 do

    %{fitness: f} = state

    state = %{state |
      fitness: f + fitness,
      status: :inactive
    }

    send_evalution_report(state)

    {:noreply, state}
  end

  def handle_cast({actuator, :sync, fitness, 0}, %{actuators: [actuator]} = state) do
    %{sensors: s, memory: m, cycles: c, fitness: f} = state

    trigger_sensors(s)

    state = %{state |
      actuators: m,
      cycles: c + 1,
      fitness: f + fitness
    }

    {:noreply, state}
  end

  def handle_cast({actuator, :sync, fitness, halt}, %{actuators: [actuator | actuators]} = state) do

    %{halts: h, fitness: f} = state

    state = %{state |
      actuators: actuators,
      halts: h + halt,
      fitness: f + fitness
    }

    {:noreply, state}
  end

  def handle_cast({actuator, :sync, fitness, halt}, state) do
    GenServer.cast(self(), {actuator, :sync, fitness, halt})

    {:noreply, state}
  end

  def handle_cast({:reactivate, exo_self}, %{exo_self: exo_self, status: :inactive} = state) do
    %{memory: memory, sensors: sensors} = state

    trigger_sensors(sensors)

    state = %{state |
      fitness: 0,
      halts: 0,
      actuators: memory,
      start_time: now(),
      status: :active
    }

    {:noreply, state}
  end

  def terminate(_reason, %{sensors: sensors, memory: actuators, neurons: neurons}) do
    [sensors, actuators, neurons]
      |> Enum.each(fn(x) ->
        Enum.each(x, &GenServer.stop/1)
      end)
  end

  defp send_evalution_report(state) do
    %{exo_self: e, start_time: s, fitness: f, cycles: c} = state

    time_diff = :timer.now_diff(now(), s)

    GenServer.cast(e, {self(), :evaluation_completed, f, c, time_diff})
  end

  defp trigger_sensors(sensors) do
    Enum.each(sensors, fn(s) ->
      Sensor.sync(s, self())
    end)
  end

  defp now do
    :erlang.timestamp
  end
end
