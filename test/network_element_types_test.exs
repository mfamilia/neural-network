defmodule NN.NetworkElementTypesTest do
  use ExUnit.Case
  require Record

  import NN.NetworkElementTypes

  test "create sensor records" do
    s = sensor(
      id: {:sensor, 123.4},
      cortex_id: {:cortex, 32.4},
      type: :type,
      vector_length: 3,
      neuron_ids: [:id],
      scape: :scape)

    assert sensor(s, :id) == {:sensor, 123.4}
    assert sensor(s, :cortex_id) == {:cortex, 32.4}
    assert sensor(s, :type) == :type
    assert sensor(s, :vector_length) == 3
    assert sensor(s, :neuron_ids) == [:id]
    assert sensor(s, :scape) == :scape
  end

  test "create actuator records" do
    s = actuator(
      id: {:actuator, 123.4},
      cortex_id: {:cortex, 32.4},
      type: :type,
      vector_length: 3,
      neuron_ids: [:id],
      scape: :scape)

    assert actuator(s, :id) == {:actuator, 123.4}
    assert actuator(s, :cortex_id) == {:cortex, 32.4}
    assert actuator(s, :type) == :type
    assert actuator(s, :vector_length) == 3
    assert actuator(s, :neuron_ids) == [:id]
    assert actuator(s, :scape) == :scape
  end

  test "create neuron records" do
    n = neuron(id: {:neuron, 24.5},
               cortex_id: {:cortex, 32.4},
               activation_function: &:math.tanh(&1),
               input_weights: [:id],
               output_ids: [:id])

    assert neuron(n, :id) == {:neuron, 24.5}
    assert neuron(n, :cortex_id) == {:cortex, 32.4}
    assert neuron(n, :activation_function) == &:math.tanh(&1)
    assert neuron(n, :input_weights) == [:id]
    assert neuron(n, :output_ids) == [:id]
  end

  test "create cortex records" do
    c = cortex(id: {:cortex, 432.4},
               sensor_ids: [:id],
               actuator_ids: [:id],
               neuron_ids: [:id])

    assert cortex(c, :id) == {:cortex, 432.4}
    assert cortex(c, :sensor_ids) == [:id]
    assert cortex(c, :actuator_ids) == [:id]
    assert cortex(c, :neuron_ids) == [:id]
  end
end
