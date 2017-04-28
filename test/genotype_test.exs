defmodule NN.GenotypeTest do
  use ExUnit.Case, async: false
  alias NN.Genotype

  require Record

  setup do
    file_name = "./test/genotype.nn"
    File.rm(file_name)

    on_exit fn ->
      File.rm(file_name)
    end

    [file_name: file_name]
  end

  test "create new server", %{file_name: file_name} do
    {:ok, sut} = Genotype.start_link(file_name)

    assert Process.alive?(sut)
  end

  test "get cortex" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    assert {:ok, cortex} = Genotype.cortex(sut)
    assert Record.is_record(cortex, :cortex)
  end

  test "get neurons" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    assert {:ok, neurons}= Genotype.neurons(sut)
    assert length(neurons) == 5
    Enum.each(neurons, fn(n)->
      assert Record.is_record(n, :neuron)
    end)
  end

  test "get sensors" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    assert {:ok, sensors}= Genotype.sensors(sut)
    assert length(sensors) == 1
    Enum.each(sensors, fn(s)->
      assert Record.is_record(s, :sensor)
    end)
  end

  test "get actuators" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    assert {:ok, actuators}= Genotype.actuators(sut)
    assert length(actuators) == 1
    Enum.each(actuators, fn(a)->
      assert Record.is_record(a, :actuator)
    end)
  end

  test "get element" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    id = {:neuron, {2, "666beba6-7f5b-49b0-8588-7f13299dc7fe"}}

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:neuron, ^id, _, _, _, _} = element
  end

  test "update element" do
    file_name = "./test/fixtures/genotypes/simple.nn"
    {:ok, sut} = Genotype.start_link(file_name)

    assert Genotype.load(sut) == :ok
    id = {:neuron, {2, "666beba6-7f5b-49b0-8588-7f13299dc7fe"}}

    Genotype.update(sut, {:foo, id})

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:foo, ^id} = element
  end

  test "save", %{file_name: file_name} do
    {:ok, sut} = Genotype.start_link(file_name)
    Genotype.new(sut)

    id = {:neuron, {2, "666beba6-7f5b-49b0-8588-7f13299dc7fe"}}

    Genotype.update(sut, {:foo, id})
    Genotype.save(sut)

    Process.sleep(100)

    {:ok, sut} = Genotype.start_link(file_name)
    Genotype.load(sut)

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:foo, ^id} = element

    File.rm(file_name)
  end
end
