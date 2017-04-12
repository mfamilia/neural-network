defmodule NN.Constructors.IdsTest do
  use ExUnit.Case
  alias NN.Constructors.Ids

  test "generate ids" do
    ids = Ids.generate_ids(2, [])

    assert length(ids) == 2
  end
end
