defmodule NN.V3.ExoSelfTest do
  use ExUnit.Case
  alias NN.Constructors.Phenotype
  alias NN.Handlers.GenotypeFile
  alias NN.Genotype

  setup do
    {:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)

    :ok
  end

  test "backup" do
    {:ok, _} = Registry.register(NN.PubSub, :network_training_complete, [])
    file_name = String.to_atom("./test/fixtures/genotypes/xor.nn")
    {:ok, genotype} = Genotype.start_link()
    {:ok, elements} = GenotypeFile.load(file_name)

    Genotype.update(genotype, elements)

    {:ok, exo_self} = Phenotype.construct(genotype)

    assert_receive {:"$gen_cast",
                    {
                      :training_complete,
                      ^exo_self,
                      _highest_fitness,
                      _evaluations,
                      _total_cycles,
                      _total_time,
                      ^genotype
                    }}
  end
end
