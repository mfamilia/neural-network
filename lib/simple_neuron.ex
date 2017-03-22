defmodule NN.SimpleNeuron do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(weights) do
    GenServer.start_link(__MODULE__, weights)
  end

  def init(weights)
    when is_nil(weights) do

    default_weights= [
      :rand.uniform-0.5,
      :rand.uniform-0.5,
      :rand.uniform-0.5
    ]

    {:ok, default_weights}
  end

  def init(weights) do
    {:ok, weights}
  end

  def weights(pid) do
    GenServer.call(pid, :weights)
  end

  def sense(pid, signal) do
    GenServer.call(pid, {:sense, signal})
  end

  def handle_call(:weights, _from, weights) do
    {:reply, weights, weights}
  end

  def handle_call({:sense, signal}, _from, weights)
    when is_list(signal) and (length(signal) == 2) do

    dot_product = dot(signal, weights, 0)
    output = [:math.tanh(dot_product)]

    {:reply, output, weights}
  end

  defp dot([i|input], [w|weights], acc) do
    dot(input, weights, i*w + acc)
  end

  defp dot([], [bias], acc) do
    acc + bias
  end
end
