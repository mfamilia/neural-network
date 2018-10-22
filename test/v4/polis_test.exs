defmodule NN.V4.PolisTest do
  use ExUnit.Case
  alias NN.V4.Polis
  import NN.V4.ScapeSummary

  setup_all do
    {:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)

    :ok
  end

  setup do
    {:ok, _} = Registry.register(NN.PubSub, :polis_updates, [])

    :ok = Polis.create()

    []
  end

  test "broadcast online/offline" do
    {:ok, _} = Polis.start()

    assert_receive {:"$gen_cast", {:polis_online}}

    :ok = Polis.stop()

    assert_receive {:"$gen_cast", {:polis_offline}}
  end

  test "reset polis" do
    assert :ok = Polis.reset()
  end

  test "start stop scapes" do
    mods = []
    scape = scape_summary(address: nil, parameters: [], type: :test)
    {:ok, _} = Polis.start({mods, [scape]})

    assert_receive {:"$gen_cast", {:polis_online}}

    {:ok, scape} = Polis.get_scape(:test)
    assert Process.alive?(scape)

    :ok = Polis.stop()
    assert_receive {:"$gen_cast", {:polis_offline}}

    refute Process.alive?(scape)
  end
end
