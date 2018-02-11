defmodule NN.V2.Neuron do
  use GenServer

  defmodule State do
    defstruct exo_self: nil,
      id: nil,
      cortex: nil,
      activation_function: nil,
      input_weights: nil,
      outputs: nil,
      memory: nil,
      accumulator: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def init(state) do
    {:ok, state}
  end

  def backup(pid, cortex) do
    GenServer.call(pid, {cortex, :backup})
  end

  def forward(pid, from, signal) do
    GenServer.cast(pid, {from, :forward, signal})
  end

  def configure(pid, exo_self, id, cortex, activation_function, input_weights, outputs) do
    GenServer.cast(pid, {exo_self, {id, cortex, activation_function, input_weights, outputs}})
  end

  def handle_call({cortex, :backup}, _from, %{cortex: cortex} = state) do
    %{id: id, memory: memory} = state

    {:reply, {self(), id, memory}, state}
  end

  def handle_cast({exo_self, {id, cortex, activation_function, input_weights, outputs}}, exo_self) do
    state = %State{
      exo_self: exo_self,
      id: id,
      cortex: cortex,
      activation_function: activation_function,
      input_weights: input_weights,
      outputs: outputs,
      memory: input_weights,
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
      memory: memory,
      activation_function: af
    } = state

    forward_signal(outputs, result + accumulator + bias, af)

    state = %{state | input_weights: memory, accumulator: 0}

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

  def tanh(value) do
    :math.tanh(value)
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
