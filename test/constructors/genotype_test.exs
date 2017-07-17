defmodule NN.Constructors.GenotypeTest do
  use ExUnit.Case
  alias NN.Constructors.Genotype

  defmodule Handler do
    use GenServer

    def start_link(listener) do
      GenServer.start_link(Handler, listener)
    end

    def handle_cast(msg, listener) do
      GenServer.cast(listener, msg)

      {:noreply, listener}
    end

    def handle_call(msg, _from, listener) do
      GenServer.cast(listener, msg)

      {:reply, nil, listener}
    end
  end

  setup do
    {:ok, handler} = Handler.start_link(self())
    hidden_layer_densities = [1, 3]
    morphology = :xor

    {:ok, pid} = Genotype.start_link(
      handler,
      morphology,
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

    assert_receive {:"$gen_cast", {:save, nil}}
  end
end
