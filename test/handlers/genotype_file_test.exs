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
    genotype = [{:foo, :id, :bar}]
    GenotypeFile.save(sut, genotype)

    Process.sleep(100)

    {:ok, store} = :ets.file2tab(String.to_atom(file_name))
    assert :ets.lookup(store, :id) == [{:foo, :id, :bar}]
  end
end
