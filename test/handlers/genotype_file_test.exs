defmodule NN.Handlers.GenotypeFileTest do
  use ExUnit.Case
  alias NN.Handlers.GenotypeFile

  setup do
    f = "./test/genotype.nn"
    File.rm(f)

    on_exit fn ->
      File.rm(f)
    end

    [
      file_path: String.to_atom(f),
      existing_file: String.to_atom("./test/fixtures/genotypes/v3.nn")
    ]
  end

  test "load elements from file", %{existing_file: f} do
    assert {:ok, elements} = GenotypeFile.load(f)
    assert 8 = length(elements)
  end

  test "save elements to file", %{file_path: f, existing_file: ef} do
    {:ok, expected_elements} = GenotypeFile.load(ef)

    assert :ok = GenotypeFile.save(f, expected_elements)
    assert {:ok, ^expected_elements} = GenotypeFile.load(f)
  end
end
