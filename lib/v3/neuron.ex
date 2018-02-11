defmodule NN.V3.Neuron do
  use GenServer

  @delta_multiplier :math.pi() * 2
  @saturation_limit :math.pi() * 2

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      cortex: nil,
      activation_function: nil,
      input_weights: nil,
      outputs: nil,
      memory_input_weights: nil,
      accumulator: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def init(state) do
    {:ok, state}
  end

  def get_backup(pid, exo_self) do
    GenServer.call(pid, {exo_self, :get_backup})
  end

  def backup(pid, exo_self) do
    GenServer.cast(pid, {exo_self, :backup})
  end

  def forward(pid, from, signal) do
    GenServer.cast(pid, {from, :forward, signal})
  end

  def perturb(pid, exo_self) do
    GenServer.cast(pid, {exo_self, :perturb})
  end

  def restore(pid, exo_self) do
    GenServer.cast(pid, {exo_self, :restore})
  end


  def configure(pid, exo_self, id, cortex, activation_function, input_weights, outputs) do
    GenServer.cast(pid, {exo_self, {id, cortex, activation_function, input_weights, outputs}})
  end

  def handle_call({exo_self, :get_backup}, _from, %{exo_self: exo_self} = state) do
    %{id: id, memory_input_weights: m} = state

    {:reply, {self(), id, m}, state}
  end

  def handle_cast({exo_self, {id, cortex, activation_function, input_weights, outputs}}, exo_self) do
    Random.seed()

    state = %State{
      exo_self: exo_self,
      id: id,
      cortex: cortex,
      activation_function: activation_function,
      input_weights: input_weights,
      outputs: outputs,
      memory_input_weights: input_weights,
      accumulator: 0
    }

    {:noreply, state}
  end

  def handle_cast({from, :forward, signal}, %{input_weights: [{from, weights}]} = state) do
    handle_cast({from, :forward, signal}, %{state | input_weights: [{from, weights} | [0]]})
  end

  def handle_cast({from, :forward, signal}, %{input_weights: [{from, weights} | [bias]]} = state) when is_number(bias) do
    result = dot_product(signal, weights)

    %{
      outputs: outputs,
      accumulator: accumulator,
      memory_input_weights: m,
      activation_function: af
    } = state

    forward_signal(outputs, result + accumulator + bias, af)

    state = %{state | input_weights: m, accumulator: 0}

    {:noreply, state}
  end

  def handle_cast({from, :forward, signal}, %{input_weights: [{from, weights} | input_weights]} = state) do
    %{accumulator: accumulator} = state

    result = dot_product(signal, weights)

    state = %{state | input_weights: input_weights, accumulator: result + accumulator}

    {:noreply, state}
  end

  def handle_cast({from, :forward, signal}, state) do
    forward(self(), from, signal)

    {:noreply, state}
  end

  def handle_cast({exo_self, :backup}, %{exo_self: exo_self} = state) do
    %{input_weights: input_weights} = state

    Process.put(:input_weights, input_weights)

    {:noreply, state}
  end

  def handle_cast({exo_self, :restore}, %{exo_self: exo_self} = state) do
    input_weights = Process.get(:input_weights)

    state = %{state |
      input_weights: input_weights,
      memory_input_weights: input_weights
    }

    {:noreply, state}
  end

  def handle_cast({exo_self, :perturb}, %{exo_self: exo_self} = state) do
    %{input_weights: i} = state

    input_weights = perturb_input_weights(i)

    state = %{state |
      input_weights: input_weights,
      memory_input_weights: input_weights
    }

    {:noreply, state}
  end

  def tanh(value) do
    :math.tanh(value)
  end

  defp perturb_input_weights(input_weights) do
    total_weights = Enum.filter(input_weights, fn(element) ->
      match?({_, _weights}, element)
    end)
    |> Enum.reduce(0, fn(x, acc) ->
      {_, weights} = x
      acc + length(weights)
    end)

    probability = 1 / :math.sqrt(total_weights)

    perturb_input_weights(probability, input_weights, [])
  end

  defp perturb_input_weights(probability, [{input, weights} | input_weights], acc) do
    updated_weights = perturb_weights(probability, weights, [])

    perturb_input_weights(probability, input_weights, [{input, updated_weights} | acc])
  end

  defp perturb_input_weights(probability, [bias], acc) do
    updated_bias = case Random.uniform < probability do
      true ->
        value = (Random.uniform - 0.5) * @delta_multiplier + bias

        saturate(value, - @saturation_limit, @saturation_limit)
      false ->
        bias
    end

    Enum.reverse([updated_bias | acc])
  end

  defp perturb_input_weights(_probability, [], acc) do
    Enum.reverse(acc)
  end

  defp perturb_weights(probability, [w | weights], acc) do
    updated_weight = case Random.uniform < probability do
      true ->
        value = (Random.uniform - 0.5) * @delta_multiplier + w

        saturate(value, - @saturation_limit, @saturation_limit)
      false ->
        w
    end

    perturb_weights(probability, weights, [updated_weight | acc])
  end

  defp perturb_weights(_probability, [], acc) do
    Enum.reverse(acc)
  end

  defp saturate(value, min, max) do
    cond do
      value < min ->
        min
      value > max ->
        max
      true ->
        value
    end
  end

  defp forward_signal(outputs, signal, activation_function) do
    result = apply(__MODULE__, activation_function, [signal])
    from = self()

    Enum.each(outputs, fn(x) ->
      forward(x, from, [result])
    end)
  end

  defp dot_product(input, weights) do
    dot_product(input, weights, 0)
  end

  defp dot_product([i | input], [w | weights], acc) do
    dot_product(input, weights, i*w + acc)
  end

  defp dot_product([], [], acc) do
    acc
  end
end
