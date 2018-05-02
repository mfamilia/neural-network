defmodule NN.Scapes.XORTest do
  use ExUnit.Case
  alias NN.Scapes.Xor
  alias NN.Scape

  setup do
    exo_self = self()
    {:ok, sut} = Xor.start_link(exo_self)

    [sut: sut, exo_self: exo_self]
  end

  test "create process", %{sut: sut} do
    assert Process.alive?(sut)
  end

  test "sense and action all correct", %{sut: sut, exo_self: exo_self} do
    assert {:percept, [-1, -1]} == Scape.sense(exo_self, sut)
    output = [-1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [1, -1]} == Scape.sense(exo_self, sut)
    output = [1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [-1, 1]} == Scape.sense(exo_self, sut)
    output = [1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [1, 1]} == Scape.sense(exo_self, sut)
    output = [-1]
    assert {:fitness, 99999.99999999999, 1} == Scape.action(exo_self, sut, output)
  end

  test "sense and action all wrong", %{sut: sut, exo_self: exo_self} do
    assert {:percept, [-1, -1]} == Scape.sense(exo_self, sut)
    output = [1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [1, -1]} == Scape.sense(exo_self, sut)
    output = [-1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [-1, 1]} == Scape.sense(exo_self, sut)
    output = [-1]
    assert {:fitness, 0, 0} == Scape.action(exo_self, sut, output)

    assert {:percept, [1, 1]} == Scape.sense(exo_self, sut)
    output = [1]
    assert {:fitness, 0.35355214059769313, 1} == Scape.action(exo_self, sut, output)
  end

  test "test reset after complete cycle", %{sut: sut, exo_self: exo_self} do
    Scape.sense(exo_self, sut)
    output = [1]
    Scape.action(exo_self, sut, output)

    Scape.sense(exo_self, sut)
    output = [-1]
    Scape.action(exo_self, sut, output)

    Scape.sense(exo_self, sut)
    output = [-1]
    Scape.action(exo_self, sut, output)

    Scape.sense(exo_self, sut)
    output = [1]
    Scape.action(exo_self, sut, output)

    assert {:percept, [-1, -1]} == Scape.sense(exo_self, sut)
  end
end
