defmodule NN.ScapeTest do
  use ExUnit.Case
  alias NN.Scape

  test "start_link" do
    exo_self = self()
    scape_type = :xor

    {:ok, sut} =
      Scape.start_link(
        exo_self,
        scape_type
      )

    assert Process.alive?(sut)
  end
end
