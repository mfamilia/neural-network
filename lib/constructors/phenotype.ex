defmodule NN.Constructors.Phenotype do
  import NN.NetworkElementTypes
  import Record

  alias NN.V3.{ExoSelf, Cortex, Sensor, Actuator, Neuron}
  alias NN.Scape
  alias NN.Genotype

  def construct(genotype) do
    Random.seed()

    {:ok, cortex} = Genotype.cortex(genotype)
    {:ok, sensors} = Genotype.sensors(genotype)
    {:ok, neurons} = Genotype.neurons(genotype)
    {:ok, actuators} = Genotype.actuators(genotype)

    store = :ets.new(:pid_store, [:set, :private])
    sensor_ids = cortex(cortex, :sensor_ids)
    actuator_ids = cortex(cortex, :actuator_ids)
    neuron_ids = cortex(cortex, :neuron_ids)
    cortex_id = cortex(cortex, :id)
    {:ok, exo_self} = ExoSelf.start_link

    start_scapes(exo_self, store, sensors, actuators)

    start_network_elements(exo_self, store, Cortex, [cortex_id])
    start_network_elements(exo_self, store, Sensor, sensor_ids)
    start_network_elements(exo_self, store, Actuator, actuator_ids)
    start_network_elements(exo_self, store, Neuron, neuron_ids)

    cortex_pid = :ets.lookup_element(store, cortex_id, 2)

    link_network_elements(sensors, store, cortex_pid, exo_self)
    link_network_elements(neurons, store, cortex_pid, exo_self)
    link_network_elements(actuators, store, cortex_pid, exo_self)

    {_sensors, neuron_pids, _actuators} = link_cortex(
      exo_self,
      cortex_pid,
      cortex_id,
      sensor_ids,
      actuator_ids,
      neuron_ids,
      store
    )

    ExoSelf.configure(exo_self, cortex_pid, neuron_pids, genotype)

    {:ok, exo_self}
  end

  defp start_network_elements(exo_self, store, type, [id | ids]) do
    {:ok, element} = type.start_link(exo_self)
    :ets.insert(store, {id, element})
    :ets.insert(store, {element, id})

    start_network_elements(exo_self, store, type, ids)
  end

  defp start_network_elements(_exo_self, _store, _type, []) do
    :ok
  end

  defp start_scapes(exo_self, store, sensors, actuators) do
    unique_scape_types(sensors, actuators)
    |> Enum.each(fn({:private, type}) ->
      {:ok, scape} = Scape.start_link(exo_self, type)
      :ets.insert(store, {type, scape})
      :ets.insert(store, {scape, type})
    end)
  end

  defp unique_scape_types(sensors, actuators) do
    sensor_scape_types = sensors
    |> Enum.map(fn(s) ->
      sensor(s, :scape)
    end)

    actuator_scape_types = actuators
    |> Enum.map(fn(a) ->
      actuator(a, :scape)
    end)

    Enum.uniq(sensor_scape_types ++ actuator_scape_types)
  end

  defp link_network_elements([r | records], store, cortex, exo_self)
    when is_record(r, :sensor) do

    id = sensor(r, :id)
    pid = convert_id_to_pid(id, store)
    type = sensor(r, :type)
    vl = sensor(r, :vector_length)
    neurons = convert_ids_to_pids(sensor(r, :neuron_ids), store)
    {:private, scape_type} = sensor(r, :scape)
    scape = convert_id_to_pid(scape_type, store)

    Sensor.configure(pid,
      exo_self,
      id,
      cortex,
      scape,
      type,
      vl,
      neurons
    )

    link_network_elements(records, store, cortex, exo_self)
  end

  defp link_network_elements([r | records], store, cortex, exo_self)
    when is_record(r, :actuator) do

    id = actuator(r, :id)
    pid = convert_id_to_pid(id, store)
    type = actuator(r, :type)
    neurons = convert_ids_to_pids(actuator(r, :neuron_ids), store)
    {:private, scape_type} = actuator(r, :scape)
    scape = convert_id_to_pid(scape_type, store)

    Actuator.configure(pid,
      exo_self,
      id,
      cortex,
      scape,
      type,
      neurons
    )

    link_network_elements(records, store, cortex, exo_self)
  end

  defp link_network_elements([r | records], store, cortex, exo_self)
    when is_record(r, :neuron) do

    id = neuron(r, :id)
    pid = convert_id_to_pid(id, store)
    af = neuron(r, :activation_function)
    inputs = convert_input_ids_to_pids(neuron(r, :input_weights), store)
    outputs = convert_ids_to_pids(neuron(r, :output_ids), store)

    Neuron.configure(pid,
      exo_self,
      id,
      cortex,
      af,
      inputs,
      outputs
    )

    link_network_elements(records, store, cortex, exo_self)
  end

  defp link_network_elements([], _store, _cortex, _exo_self), do: :ok

  defp link_cortex(exo_self, pid, id, sensor_ids, actuator_ids, neuron_ids, store) do
    sensors = convert_ids_to_pids(sensor_ids, store)
    actuators = convert_ids_to_pids(actuator_ids, store)
    neurons = convert_ids_to_pids(neuron_ids, store)

    Cortex.configure(pid, exo_self, id, sensors, actuators, neurons)

    {sensors, neurons, actuators}
  end

  defp convert_input_ids_to_pids(inputs, store) do
    convert_input_ids_to_pids(inputs, store, [])
  end

  defp convert_input_ids_to_pids([], _store, acc) do
    Enum.reverse(acc)
  end

  defp convert_input_ids_to_pids([{:bias, bias}], _store, acc) do
    Enum.reverse([bias | acc])
  end

  defp convert_input_ids_to_pids([{id, weights} | inputs], store, acc) do
    pid = convert_id_to_pid(id, store)
    convert_input_ids_to_pids(inputs, store, [{pid, weights, id} | acc])
  end

  defp convert_ids_to_pids(ids, store) do
    Enum.map(ids, fn(id) ->
      convert_id_to_pid(id, store)
    end)
  end

  defp convert_id_to_pid(id, store) do
    :ets.lookup_element(store, id, 2)
  end
end
