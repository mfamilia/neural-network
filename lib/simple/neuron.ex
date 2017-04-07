defmodule NN.Simple.Neuron do
  use GenServer

  def start_link(target) do
    GenServer.start_link(__MODULE__, target)
  end

  def init(target) do
    default_weights = [
      random(),
      random(),
      random()
    ]

    {:ok, {target, default_weights}}
  end

  def weights(pid) do
    GenServer.call(pid, :weights)
  end

  def sense(pid, input) do
    GenServer.cast(pid, {:forward, input})
  end

  def handle_call(:weights, _from, {_, weights} = state) do
    {:reply, weights, state}
  end

  def handle_cast({:forward, input}, {target, weights} = state)
    when is_list(input) and (length(input) == 2) do

    dot_product = dot(input, weights, 0)
    output = [:math.tanh(dot_product)]
    GenServer.cast(target, {:forward, output})

    {:noreply, state}
  end

  defp random do
    Random.uniform-0.5
  end

  defp dot([i|input], [w|weights], acc) do
    dot(input, weights, i*w + acc)
  end

  defp dot([], [bias], acc) do
    acc + bias
  end
end
