defmodule NN.V2.ExoSelfTest do
  use ExUnit.Case
  alias NN.V2.ExoSelf

  setup do
    file_name = "./test/fixtures/genotypes/simple.nn"

    {:ok, sut} = ExoSelf.start_link(file_name)

    [sut: sut]
  end

  test "create exo self", %{sut: sut} do
    assert Process.alive?(sut)
  end
end
