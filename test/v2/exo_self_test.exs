defmodule NN.V2.ExoSelfTest do
  use ExUnit.Case, async: false
  alias NN.V2.ExoSelf

  import Mock

  test "backup" do
    with_mock IO, [puts: fn(_) -> :ok end] do
      genotype_handler = self()
      file_name = "./test/fixtures/genotypes/simple.nn"
      {:ok, genotype} = :file.consult(file_name)

      {:ok, _sut} = ExoSelf.start_link(genotype_handler)

      assert_receive {:"$gen_call", from, :load}
      GenServer.reply(from, {:ok, genotype})

      assert_receive {:"$gen_cast", {:save, genotype}}
      assert length(genotype) == 8
    end
  end
end
