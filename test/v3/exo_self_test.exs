defmodule NN.V3.ExoSelfTest do
  use ExUnit.Case, async: false
  alias NN.V3.ExoSelf
  alias NN.Handlers.Genotype

  test "backup" do
    genotype = self()
    file_name = "./test/fixtures/genotypes/xor.nn"

    {:ok, source} = Genotype.start_link(file_name)
    :ok = Genotype.load(source)
    {:ok, _sut} = ExoSelf.start_link(genotype)

    assert_receive {:"$gen_call", from, :cortex}
    {:ok, cortex} = Genotype.cortex(source)
    GenServer.reply(from, {:ok, cortex})

    assert_receive {:"$gen_call", from, :sensors}
    {:ok, sensors} = Genotype.sensors(source)
    GenServer.reply(from, {:ok, sensors})

    assert_receive {:"$gen_call", from, :actuators}
    {:ok, actuators} = Genotype.actuators(source)
    GenServer.reply(from, {:ok, actuators})

    assert_receive {:"$gen_call", from, :sensors}
    {:ok, sensors} = Genotype.sensors(source)
    GenServer.reply(from, {:ok, sensors})

    assert_receive {:"$gen_call", from, :neurons}
    {:ok, neurons} = Genotype.neurons(source)
    GenServer.reply(from, {:ok, neurons})

    assert_receive {:"$gen_call", from, :actuators}
    {:ok, actuators} = Genotype.actuators(source)
    GenServer.reply(from, {:ok, actuators})

    Enum.each(1..3, fn(_) ->
      assert_receive {:"$gen_call", from, {:element, id}}
      {:ok, element} = Genotype.element(source, id)
      GenServer.reply(from, {:ok, element})
    end)

    Enum.each(1..3, fn(_) ->
      assert_receive {:"$gen_cast", {:update, _element}}
    end)

    assert_receive {:"$gen_call", _from, {:save, nil}}
  end
end
