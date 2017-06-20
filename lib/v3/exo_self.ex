defmodule NN.V3.ExoSelf do
  use GenServer
  import NN.NetworkElementTypes
  import Record

  alias NN.V3.{Cortex, Sensor, Actuator, Neuron}
  alias NN.Handlers.Genotype
  alias NN.Scape

  @io %{puts: &IO.puts/1}
  @max_attempts 50

  defmodule State do
    defstruct store: nil,
      cortex: nil,
      handler: nil,
      scapes: nil,
      highest_fitness: nil,
      evaluations: nil,
      total_cycles: nil,
      attempt: nil,
      total_time: nil,
      sensors: nil,
      neurons: nil,
      actuators: nil,
      io: nil
  end

  def start_link(handler, io \\ @io) do
    GenServer.start_link(__MODULE__, {handler, io})
  end

  def init({handler, io}) do
    configure(self())

    {:ok, {handler, io}}
  end

  def configure(pid) do
    GenServer.cast(pid, :configure)
  end

  def handle_cast(:configure, {handler, io}) do
    Random.seed()

    {:noreply, initial_state({handler, io})}
  end

  def handle_cast({cortex, :backup, neuron_data}, %{cortex: cortex} = state) do
    %{
      store: s,
      handler: handler
    } = state

    :ok = update_genotype(handler, s, neuron_data)

    Genotype.save(handler)

    {:noreply, state}
  end

  def handle_cast({cortex, :evaluation_completed, fitness, cycles, time}, %{cortex: cortex} = state) do
    %{
      highest_fitness: hf,
      attempt: a,
      neurons: neurons
    } = state

    exo_self = self()

    {highest_fitness, attempt} = case fitness > hf do
      true ->
        Enum.each(neurons, fn(n) ->
          Neuron.backup(n, exo_self)
        end)

        {fitness, 0}
      false ->
        Process.get(:perturbed)
        |> Enum.each(fn(n) ->
          Neuron.restore(n, exo_self)
        end)

        {hf, a + 1}
    end

    %{
      total_cycles: tc,
      total_time: tt,
      handler: genotype,
      store: store,
      io: io,
      evaluations: evaluations
    } = state

    total_cycles = tc + cycles
    total_time = tt + time

    case attempt >= @max_attempts do
      true ->
        backup_genotype(genotype, neurons, exo_self, store)

        io.puts.("Cortex: #{inspect cortex} finished training.
          Genotype has been backed up.\n
          Fitness: #{highest_fitness}\n
          TotalEvaluations: #{evaluations}\n
          TotCycles: #{total_cycles}\n
          TimeAcc:#{total_time}\n"
        )
      false ->
        total_neurons = length(neurons)
        probability = 1 / :math.sqrt(total_neurons)

        perturbed = neurons
        |> Enum.filter(fn(_) ->
          Random.uniform() < probability
        end)

        Enum.each(perturbed, fn(n) ->
          Neuron.perturb(n, exo_self)
        end)

        Process.put(:perturbed, perturbed)
        Cortex.reactivate(cortex, exo_self)
    end

    state = %{state |
      total_cycles: total_cycles,
      highest_fitness: highest_fitness,
      evaluations: evaluations + 1,
      total_time: total_time,
      attempt: attempt
    }

    {:noreply, state}
  end

  defp backup_genotype(genotype, neurons, exo_self, store) do
    neuron_data = neurons
    |> Enum.map(fn(n) ->
      Neuron.get_backup(n, exo_self)
    end)

    :ok = update_genotype(genotype, store, neuron_data)

    Genotype.save(genotype)
  end

  defp update_genotype(handler, store, [{pid, id, pid_weights} | neurons]) do
    {:ok, neuron} = Genotype.element(handler, id)
    updated_input_weights = convert_pid_weights_to_id_weights(pid_weights, store, [])
    updated_neuron = neuron(neuron, input_weights: updated_input_weights)

    Genotype.update(handler, updated_neuron)

    update_genotype(handler, store, neurons)
  end

  defp update_genotype(_handler, _store, []), do: :ok

  defp convert_pid_weights_to_id_weights([{pid, weights} | inputs], store, acc) do
    id = convert_pid_to_id(pid, store)
    convert_pid_weights_to_id_weights(inputs, store, [{id, weights} | acc])
  end

  defp convert_pid_weights_to_id_weights([], store, acc) do
    convert_pid_weights_to_id_weights([0], store, acc)
  end

  defp convert_pid_weights_to_id_weights([bias], _store, acc) do
    Enum.reverse([{:bias, bias} | acc])
  end

  defp initial_state({handler, io}) do
    store = :ets.new(:pid_store, [:set, :private])
    {:ok, cortex} = Genotype.cortex(handler)

    sensor_ids = cortex(cortex, :sensor_ids)
    actuator_ids = cortex(cortex, :actuator_ids)
    neuron_ids = cortex(cortex, :neuron_ids)
    cortex_id = cortex(cortex, :id)
    exo_self = self()

    scapes = start_scapes(exo_self, store, handler)

    start_network_elements(exo_self, store, Cortex, [cortex_id])
    start_network_elements(exo_self, store, Sensor, sensor_ids)
    start_network_elements(exo_self, store, Actuator, actuator_ids)
    start_network_elements(exo_self, store, Neuron, neuron_ids)

    cortex_pid = :ets.lookup_element(store, cortex_id, 2)

    {:ok, sensors} = Genotype.sensors(handler)
    link_network_elements(sensors, store, cortex_pid, exo_self)

    {:ok, neurons} = Genotype.neurons(handler)
    link_network_elements(neurons, store, cortex_pid, exo_self)

    {:ok, actuators} = Genotype.actuators(handler)
    link_network_elements(actuators, store, cortex_pid, exo_self)

    {sensors, neurons, actuators} = link_cortex(
      exo_self,
      cortex_pid,
      cortex_id,
      sensor_ids,
      actuator_ids,
      neuron_ids,
      store
    )

    %State{
      handler: handler,
      store: store,
      cortex: cortex_pid,
      scapes: scapes,
      highest_fitness: 0,
      evaluations: 0,
      total_cycles: 0,
      total_time: 0,
      attempt: 1,
      sensors: sensors,
      neurons: neurons,
      actuators: actuators,
      io: io
    }
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

  defp start_scapes(exo_self, store, genotype) do
    unique_scape_types(genotype)
    |> Enum.map(fn({:private, type}) ->
      {:ok, scape} = Scape.start_link(exo_self, type)
      :ets.insert(store, {type, scape})
      :ets.insert(store, {scape, type})

      scape
    end)
  end

  defp unique_scape_types(genotype) do
    {:ok, sensors} = Genotype.sensors(genotype)

    sensor_scape_types = sensors
    |> Enum.map(fn(s) ->
      sensor(s, :scape)
    end)

    {:ok, actuators} = Genotype.actuators(genotype)

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

  defp link_network_elements([], _store, _cortex, _exo_self) do
    :ok
  end

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
    convert_input_ids_to_pids(inputs, store, [{pid, weights} | acc])
  end

  defp convert_ids_to_pids(ids, store) do
    Enum.map(ids, fn(id) ->
      convert_id_to_pid(id, store)
    end)
  end

  defp convert_id_to_pid(id, store) do
    :ets.lookup_element(store, id, 2)
  end

  defp convert_pid_to_id(id, store) do
    convert_id_to_pid(id, store)
  end
end
