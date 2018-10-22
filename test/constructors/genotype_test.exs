defmodule NN.Constructors.GenotypeTest do
  use ExUnit.Case
  alias NN.Constructors.Genotype, as: Constructor
  alias NN.Genotype

  setup do
    morphology = :xor
    hidden_layer_densities = [2]

    {:ok, sut} =
      Constructor.construct(
        morphology,
        hidden_layer_densities
      )

    [sut: sut]
  end

  test "create genotype", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "create elements", %{sut: sut} do
    assert {:ok, _cortex} = Genotype.cortex(sut)
    assert {:ok, _sensors} = Genotype.sensors(sut)
    assert {:ok, _neurons} = Genotype.neurons(sut)
    assert {:ok, _actuators} = Genotype.actuators(sut)
  end
end
