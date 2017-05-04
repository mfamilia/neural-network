defmodule NN.Constructors.GenotypeTest do
  use ExUnit.Case
  alias NN.Constructors.Genotype

  setup do
    handler = self()
    sensor_type = :random
    actuator_type = :print_results
    hidden_layer_densities = [1, 3]

    {:ok, pid} = Genotype.start_link(handler,
      sensor_type,
      actuator_type,
      hidden_layer_densities)

    [sut: pid]
  end

  test "create genotype constructor", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "create elements", %{sut: sut} do
    Genotype.construct(sut)

    Enum.each(1..8, fn(_) ->
      assert_receive {:"$gen_cast", {:update, _element}}
    end)

    assert_receive {:"$gen_cast", :save}
  end
end
