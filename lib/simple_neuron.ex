defmodule NN.SimpleNeuron do
  def create do
    weights = [:random.uniform-0.5,
               :random.uniform-0.5,
               :random.uniform-0.5]

    pid = spawn __MODULE__, :loop, [weights]

    Process.register(pid, :neuron)
  end

  def loop(weights) do
    receive do
      {caller, input} ->
        IO.puts "**** Processing ****"
        :io.format("Input: ~p~n", [input])
        :io.format("Weights: ~p~n", [weights])
        dot_product = dot(input, weights, 0)
        output = [:math.tanh(dot_product)]
        send caller, {:result, output}
        loop(weights)
    end
  end

  defp dot([i|input], [w|weights], acc) do
    dot(input, weights, i*w + acc)
  end
  defp dot([], [bias], acc) do
    acc + bias
  end

  def sense(signal) do
    case is_list(signal) and (length(signal) == 2) do
      true ->
        send :neuron, {self(), signal}
        receive do
          {:result, output} ->
            :io.format("Output: ~p~n", [output])
        end
      false ->
        IO.puts "The signal must be a list of length 2"
    end
  end
end
