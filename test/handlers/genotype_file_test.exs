defmodule NN.Handlers.GenotypeFileTest do
  use ExUnit.Case
  alias NN.Handlers.GenotypeFile

  setup do
    file_name = "test_genotype_file.nn"
    File.rm(file_name)

    {:ok, sut} = GenotypeFile.start_link(file_name)

    on_exit fn ->
      File.rm(file_name)
    end

    [sut: sut, file_name: file_name]
  end

  test "create genotype file", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "save genotype to file", %{sut: sut, file_name: file_name} do
    genotype = [:foobar]
    GenotypeFile.save(sut, genotype)

    Process.sleep(100)

    assert {:ok, "foobar.\n"} = File.read(file_name)
  end

  test "load genotype from file" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = GenotypeFile.start_link(file_name)
    {:ok, genotype} = GenotypeFile.load(sut)

    assert length(genotype) == 8
  end
end
