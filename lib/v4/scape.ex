defmodule NN.V4.Scape do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({owner, _type, _params}) do
    {:ok, %{owner: owner}}
  end

  def stop(pid, owner) do
    GenServer.cast(pid, {:stop, :normal, owner})
  end

  def handle_cast({:stop, :normal, owner}, %{owner: owner} = state) do
    {:stop, :normal, state}
  end
end
