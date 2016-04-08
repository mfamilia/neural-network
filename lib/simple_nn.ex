defmodule NN.SimpleNN do
  def create do
    weights = [:random.uniform-0.5,
               :random.uniform-0.5,
               :random.uniform-0.5]

    neuron_pid = spawn __MODULE__, :neuron, [weights, nil, nil]
    sensor_pid = spawn __MODULE__, :sensor, [neuron_pid]
    actuator_pid = spawn __MODULE__, :actuator, [neuron_pid]

    send neuron_pid, {:init, sensor_pid, actuator_pid}

    cortex_pid = spawn __MODULE__, :cortex, [sensor_pid, neuron_pid, actuator_pid]
    Process.register(cortex_pid, :cortex)
  end

  def neuron(weights, sensor_pid, actuator_pid) do
    receive do
      {^sensor_pid, :forward, input} ->
        :io.format("**** Thinking ****~n Input:~p~n Weights: ~p~n", [input, weights])
        dot_product = dot(input, weights, 0)
        output = [:math.tanh(dot_product)]

        send actuator_pid, {self(), :forward, output}
        neuron(weights, sensor_pid, actuator_pid)
      {:init, new_sensor_pid, new_actuator_pid} ->
        neuron(weights, new_sensor_pid, new_actuator_pid)
      :terminate ->
        :ok
    end
  end

  def sensor(neuron_pid) do
    receive do
      :sync ->
        sensory_signal = [:random.uniform, :random.uniform]
        :io.format("**** Sensing ****:~n Signal from the environment ~p~n", [sensory_signal])

        send neuron_pid, {self(), :forward, sensory_signal}
        sensor(neuron_pid)
      :terminate ->
        :ok
    end
  end

  def actuator(neuron_pid) do
    receive do
      {^neuron_pid, :forward, control_signal} ->
        pts(control_signal)
        actuator(neuron_pid)
      :terminate ->
        :ok
    end
  end

  def cortex(sensor_pid, neuron_pid, actuator_pid) do
    receive do
      :sense_think_act ->
        send sensor_pid, :sync
        cortex(sensor_pid, neuron_pid, actuator_pid)
      :terminate ->
        send sensor_pid, :terminate
        send neuron_pid, :terminate
        send actuator_pid, :terminate
        :ok
    end
  end

  defp pts(control_signal) do
    :io.format("**** Acting ****:~n Using ~p to act on environment.~n", [control_signal])
  end

  defp dot([i|input], [w|weights], acc) do
    dot(input, weights, i*w + acc)
  end
  defp dot([], [bias], acc) do
    acc + bias
  end
end
