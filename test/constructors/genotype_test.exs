defmodule NN.Constructors.GenotypeTest do
  use ExUnit.Case
  alias NN.Constructors.Genotype

  setup do
    handler = self()
    sensor_type = :rng
    actuator_type = :pts
    hidden_layer_densities = [1, 3]

    {:ok, pid} = Genotype.start_link(handler,
      sensor_type,
      actuator_type,
      hidden_layer_densities)

    [sut: pid]
  end

  test "create genotype constructor", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "create neuron layers", %{sut: sut} do
    Genotype.construct_genotype(sut)

    assert_receive {:"$gen_cast", {:genotype, genotype}}
    assert [_cortex, _sensor, _actuator | neurons] = genotype
    assert length(neurons) == 5
  end

  test "create cortex", %{sut: sut} do
    Genotype.construct_genotype(sut)

    assert_receive {:"$gen_cast", {:genotype, genotype}}
    assert [cortex | _] = genotype
    assert {:cortex, id, sensors, actuators, neurons} = cortex
    assert {:cortex, _uuid} = id
    assert [{:sensor, _uuid}] = sensors
    assert [{:actuator, _uuid}] = actuators
    assert length(neurons) == 5

    Enum.each(neurons, fn(n) ->
      assert {:neuron, {_index, _uuid}} = n
    end)
  end

  test "create sensor", %{sut: sut} do
    Genotype.construct_genotype(sut)

    assert_receive {:"$gen_cast", {:genotype, genotype}}
    assert [_cortex, sensor | _] = genotype
    assert {:sensor, id, cortex_id, :rng, 2, neurons} = sensor
    assert {:sensor, _uuid} = id
    assert {:cortex, _uuid} = cortex_id
    assert [{:neuron, {1, _uuid}}] = neurons
  end

  test "create actuator", %{sut: sut} do
    Genotype.construct_genotype(sut)

    assert_receive {:"$gen_cast", {:genotype, genotype}}
    assert [_cortex, _sensor, actuator | _] = genotype
    assert {:actuator, id, cortex_id, :pts, 1, neurons} = actuator
    assert {:actuator, _uuid} = id
    assert {:cortex, _uuid} = cortex_id
    assert [{:neuron, {3, _uuid}}] = neurons
  end
end
