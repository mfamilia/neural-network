defmodule NN.V2.ExoSelf do
  use GenServer
  import NN.NetworkElementTypes
  import Record

  alias NN.V2.{Cortex, Sensor, Actuator, Neuron}
  alias NN.Handlers.Genotype, as: Handler

  defmodule State do
    defstruct store: nil,
              cortex: nil,
              handler: nil
  end

  def start_link(handler) do
    GenServer.start_link(__MODULE__, handler)
  end

  def init(handler) do
    configure(self())

    {:ok, handler}
  end

  def configure(pid) do
    GenServer.cast(pid, :configure)
  end

  def backup(pid, from, data) do
    GenServer.cast(pid, {from, :backup, data})
  end

  def handle_cast(:configure, handler) do
    {:noreply, initial_state(handler)}
  end

  def handle_cast({cortex, :backup, neuron_data}, %{cortex: cortex, handler: handler} = state) do
    %{store: s} = state

    :ok = update_genotype(handler, s, neuron_data)

    Handler.save(handler)

    {:noreply, state}
  end

  defp update_genotype(handler, store, [{id, pid_weights} | neurons]) do
    {:ok, neuron} = Handler.element(handler, id)
    updated_input_weights = convert_pid_weights_to_id_weights(pid_weights, store, [])
    updated_neuron = neuron(neuron, input_weights: updated_input_weights)

    Handler.update(handler, updated_neuron)

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

  defp initial_state(handler) do
    store = :ets.new(:pid_store, [:set, :private])
    {:ok, cortex} = Handler.cortex(handler)

    sensor_ids = cortex(cortex, :sensor_ids)
    actuator_ids = cortex(cortex, :actuator_ids)
    neuron_ids = cortex(cortex, :neuron_ids)
    cortex_id = cortex(cortex, :id)
    exo_self = self()

    start_network_elements(exo_self, store, Cortex, [cortex_id])
    start_network_elements(exo_self, store, Sensor, sensor_ids)
    start_network_elements(exo_self, store, Actuator, actuator_ids)
    start_network_elements(exo_self, store, Neuron, neuron_ids)

    cortex_pid = :ets.lookup_element(store, cortex_id, 2)

    {:ok, sensors} = Handler.sensors(handler)
    link_network_elements(sensors, store, cortex_pid, exo_self)

    {:ok, neurons} = Handler.neurons(handler)
    link_network_elements(neurons, store, cortex_pid, exo_self)

    {:ok, actuators} = Handler.actuators(handler)
    link_network_elements(actuators, store, cortex_pid, exo_self)

    link_cortex(
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
      cortex: cortex_pid
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

  defp link_network_elements([r | records], store, cortex, exo_self)
       when is_record(r, :sensor) do
    id = sensor(r, :id)
    pid = convert_id_to_pid(id, store)
    type = sensor(r, :type)
    vl = sensor(r, :vector_length)
    neurons = convert_ids_to_pids(sensor(r, :neuron_ids), store)

    Sensor.configure(
      pid,
      exo_self,
      id,
      cortex,
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

    Actuator.configure(
      pid,
      exo_self,
      id,
      cortex,
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

    Neuron.configure(
      pid,
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
    cycles = 1000

    Cortex.configure(pid, exo_self, id, sensors, actuators, neurons, cycles)
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
    Enum.map(ids, fn id ->
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
