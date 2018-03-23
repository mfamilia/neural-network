defmodule NN.GenotypeTest do
  use ExUnit.Case
  alias NN.Genotype
  alias NN.Handlers.GenotypeFile
  import NN.NetworkElementTypes

  setup do
    {:ok, sut} = Genotype.start_link

    [sut: sut]
  end

  test "create genotype process", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "get/update cortex element", %{sut: sut} do
    c = cortex(id: :cortex, sensor_ids: "sensor_ids", actuator_ids: "actuator_ids", neuron_ids: "neuron_ids")

    Genotype.update(sut, c)

    assert {:ok, ^c} = Genotype.cortex(sut)
  end

  test "get/update sensor elements", %{sut: sut} do
    s = sensor(id: :id, type: :get_input, scape: {:private, :xor}, vector_length: 2)

    Genotype.update(sut, s)

    assert {:ok, [^s]} = Genotype.sensors(sut)
  end

  test "get/update actuator elements", %{sut: sut} do
    a = actuator(id: :id, type: :send_output, scape: {:private, :xor}, vector_length: 1)

    Genotype.update(sut, a)

    assert {:ok, [^a]} = Genotype.actuators(sut)
  end

  test "get/update neuron elements", %{sut: sut} do
    n = neuron(id: :id,
      cortex_id: "cortex_id",
      activation_function: :tanh,
      input_weights: "input_weights",
      output_ids: "output_ids")

    Genotype.update(sut, n)

    assert {:ok, [^n]} = Genotype.neurons(sut)
  end

  test "find element" do
    file_name = String.to_atom("./test/fixtures/genotypes/xor.nn")
    {:ok, genotype} = Genotype.start_link
    {:ok, elements} = GenotypeFile.load(file_name)

    Genotype.update(genotype, elements)

    id = {:neuron, {1, "6067adbb-90a1-4f26-a56b-2e41a7e55ce4"}}
    assert {:ok, neuron} = Genotype.element(genotype, id)
    assert {:neuron, ^id, _cortex, _af, _kinput_weights, _outputs} = neuron
  end
end
