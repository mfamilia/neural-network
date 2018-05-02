defmodule NN.Handlers.GenotypeTest do
  use ExUnit.Case, async: false
  alias NN.Handlers.Genotype

  require Record

  setup do
    io = %{puts: fn(msg) -> send(self(), {:puts, msg}) end}

    file_name = "./test/genotype.nn"
    File.rm(file_name)

    on_exit fn ->
      File.rm(file_name)
    end

    [file_name: file_name, io: io]
  end

  test "create new server", %{file_name: file_name, io: io} do
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Process.alive?(sut)
  end

  test "get cortex", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    assert {:ok, cortex} = Genotype.cortex(sut)
    assert Record.is_record(cortex, :cortex)
  end

  test "get neurons", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    assert {:ok, neurons}= Genotype.neurons(sut)
    assert length(neurons) == 5
    Enum.each(neurons, fn(n)->
      assert Record.is_record(n, :neuron)
    end)
  end

  test "get sensors", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    assert {:ok, sensors}= Genotype.sensors(sut)
    assert length(sensors) == 1
    Enum.each(sensors, fn(s)->
      assert Record.is_record(s, :sensor)
    end)
  end

  test "get actuators", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    assert {:ok, actuators}= Genotype.actuators(sut)
    assert length(actuators) == 1
    Enum.each(actuators, fn(a)->
      assert Record.is_record(a, :actuator)
    end)
  end

  test "get element", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    id = {:neuron, {2, "74a39191-eb74-4f39-8a4e-aba847f3d6c4"}}

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:neuron, ^id, _, _, _, _} = element
  end

  test "update element", %{io: io} do
    file_name = "./test/fixtures/genotypes/v2.nn"
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok
    id = {:neuron, {2, "666beba6-7f5b-49b0-8588-7f13299dc7fe"}}

    Genotype.update(sut, {:foo, id})

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:foo, ^id} = element
  end

  test "save", %{file_name: file_name, io: io} do
    {:ok, sut} = Genotype.start_link(file_name, io)
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

  test "save to different file", %{file_name: file_name, io: io} do
    {:ok, sut} = Genotype.start_link(file_name, io)
    Genotype.new(sut)

    id = {:neuron, {2, "666beba6-7f5b-49b0-8588-7f13299dc7fe"}}

    Genotype.update(sut, {:foo, id})

    new_file_name = "./test/genotype2.nn"
    File.rm(new_file_name)
    Genotype.save(sut, new_file_name)

    Process.sleep(100)

    {:ok, sut} = Genotype.start_link(new_file_name, io)
    Genotype.load(sut)

    assert {:ok, element} = Genotype.element(sut, id)
    assert {:foo, ^id} = element

    File.rm(new_file_name)
  end

  test "print" do
    file_name = "./test/fixtures/genotypes/v2.nn"
    self = self()
    io = %{puts: fn(msg) -> send(self, {:puts, msg}) end}
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok

    Genotype.print(sut)

    Enum.each(1..8, fn(_) ->
      assert_receive {:puts, _element}
    end)

    refute_receive {:puts, _element}
  end

  test "rename" do
    file_name = "./test/fixtures/genotypes/v2.nn"
    self = self()
    io = %{puts: fn(msg) -> send(self, {:puts, msg}) end}
    {:ok, sut} = Genotype.start_link(file_name, io)

    assert Genotype.load(sut) == :ok

    new_file_name = "./test/fixtures/genotypes/rename.nn"
    File.rm(new_file_name)
    Genotype.rename(sut, new_file_name)
    Genotype.save(sut)

    Process.sleep(100)

    assert File.exists?(new_file_name)
  end
end
