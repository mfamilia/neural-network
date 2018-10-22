defmodule NN.V1.NN do
  use GenServer
  alias NN.V1.{Cortex, Env}

  defmodule State do
    defstruct cortex: nil,
              env: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, %State{})
  end

  def init(state) do
    {:ok, e} = Env.start_link()
    {:ok, c} = Cortex.start_link(e)

    {:ok, %{state | cortex: c, env: e}}
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def sense_think_act(pid) do
    GenServer.cast(pid, :sense_think_act)
  end

  def handle_cast(:sense_think_act, %{cortex: c} = state) do
    Cortex.sense_think_act(c)

    {:noreply, state}
  end

  def terminate(_reason, %{cortex: c, env: e}) do
    [c, e]
    |> Enum.each(fn x ->
      GenServer.stop(x)
    end)
  end
end
