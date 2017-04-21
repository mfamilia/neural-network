defmodule NN.V2.ExoSelfTest do
  use ExUnit.Case, async: false
  alias NN.V2.ExoSelf

  import Mock

  test "backup" do
    with_mock IO, [puts: fn(_) -> :ok end] do
      genotype_handler = self()
      file_name = "./test/fixtures/genotypes/simple.nn"

      {:ok, sut} = ExoSelf.start_link(file_name, genotype_handler)
      assert Process.alive?(sut)

      assert_receive {:"$gen_cast", {:genotype, _genotype}}
    end
  end
end
