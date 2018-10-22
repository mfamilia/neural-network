defmodule NN.V4.Polis do
  use GenServer

  import NN.V4.{
    NetworkElementTypes,
    ScapeSummary
  }

  import Keyword, only: [keys: 1]

  alias :mnesia, as: Mnesia
  alias NN.V4.Scape

  @mods []
  @public_scapes []

  defmodule State do
    defstruct active_mods: nil,
              active_scapes: nil
  end

  def start(), do: start({@mods, @public_scapes})

  def start({mods, public_scapes}) do
    GenServer.start(__MODULE__, {mods, public_scapes}, name: __MODULE__)
  end

  def init({mods, public_scapes}) do
    Random.seed()
    Process.flag(:trap_exit, true)
    Mnesia.start()

    :ok = start_mods(mods)
    scapes = start_scapes(public_scapes)

    GenServer.cast(__MODULE__, :online)
    {:ok, %State{active_mods: mods, active_scapes: scapes}}
  end

  def get_scape(type), do: GenServer.call(__MODULE__, {:get_scape, type})

  def create do
    Mnesia.create_schema([node()])
    Mnesia.start()

    Mnesia.create_table(:agent, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(agent(agent()))}
    ])

    Mnesia.create_table(:cortex, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(cortex(cortex()))}
    ])

    Mnesia.create_table(:neuron, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(neuron(neuron()))}
    ])

    Mnesia.create_table(:sensor, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(sensor(sensor()))}
    ])

    Mnesia.create_table(:actuator, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(actuator(actuator()))}
    ])

    Mnesia.create_table(:population, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(population(population()))}
    ])

    Mnesia.create_table(:specie, [
      {:disc_copies, [node()]},
      {:type, :set},
      {:attributes, keys(specie(specie()))}
    ])

    :ok
  end

  def reset() do
    Mnesia.stop()
    :ok = Mnesia.delete_schema([node()])
    create()
  end

  def stop(), do: GenServer.stop(__MODULE__)

  def handle_call({:get_scape, type}, _from, state) do
    pid =
      case Enum.find(state.active_scapes, fn s ->
             scape_summary(s, :type) == type
           end) do
        nil -> nil
        scape -> scape_summary(scape, :address)
      end

    {:reply, {:ok, pid}, state}
  end

  def handle_cast(:online, state) do
    Registry.dispatch(NN.PubSub, :polis_updates, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, {
          :polis_online
        })
      end
    end)

    {:noreply, state}
  end

  def terminate(:normal, %{active_mods: m, active_scapes: s}) do
    stop_mods(m)
    stop_scapes(s)

    Registry.dispatch(NN.PubSub, :polis_updates, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, {
          :polis_offline
        })
      end
    end)
  end

  defp start_mods(mods) do
    Enum.each(mods, fn m -> m.start() end)
  end

  defp stop_mods(mods) do
    Enum.each(mods, fn m -> m.stop() end)
  end

  defp start_scapes(scapes) do
    owner = self()

    Enum.map(scapes, fn s ->
      scape_summary(type: t, parameters: p) = s
      {:ok, pid} = Scape.start_link({owner, t, p})

      scape_summary(s, address: pid)
    end)
  end

  defp stop_scapes(scapes) do
    owner = self()

    Enum.each(scapes, fn s ->
      scape_summary(address: pid) = s

      Scape.stop(pid, owner)
    end)

    :ok
  end
end
