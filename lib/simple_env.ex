defmodule NN.SimpleEnv do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def sense(pid) do
    GenServer.call(pid, :sense)
  end

  def act(pid, output) do
    GenServer.cast(pid, {:act, output})
  end

  def handle_call(:sense, _from, state) do
    input = [Random.uniform, Random.uniform]

    IO.puts "****Sensing****:"
    IO.puts "Signal from the environment: #{inspect input}"

    {:reply, input, state}
  end

  def handle_cast({:act, output}, state) do
    IO.puts "****Acting****:"
    IO.puts "Using: #{inspect output} to act on environment."

    {:noreply, state}
  end
end
