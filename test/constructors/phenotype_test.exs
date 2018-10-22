defmodule NN.Constructors.PhenotypeTest do
  use ExUnit.Case
  alias NN.Constructors.Genotype
  alias NN.Constructors.Phenotype

  setup do
    morphology = :xor
    hidden_layer_densities = [2]

    {:ok, genotype} =
      Genotype.construct(
        morphology,
        hidden_layer_densities
      )

    [genotype: genotype]
  end

  test "create processes", %{genotype: genotype} do
    {:ok, exo_self} = Phenotype.construct(genotype)

    assert Process.alive?(exo_self)
  end
end
