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

  test "write genotype file", %{sut: sut, file_name: file_name} do
    genotype = [:foobar]
    GenotypeFile.write_to_file(sut, genotype)

    Process.sleep(100)

    assert {:ok, "foobar\n"} = File.read(file_name)
  end
end
