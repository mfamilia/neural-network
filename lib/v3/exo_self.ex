defmodule NN.V3.ExoSelf do
  use GenServer

  import NN.NetworkElementTypes

  alias NN.V3.{Cortex, Neuron}
  alias NN.Genotype

  @max_attempts 50

  defmodule State do
    defstruct cortex: nil,
      highest_fitness: nil,
      evaluations: nil,
      total_cycles: nil,
      attempt: nil,
      total_time: nil,
      neurons: nil,
      genotype: nil
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %State{})
  end

  def init(state) do
    {:ok, state}
  end

  def configure(pid, cortex, neurons, genotype) do
    GenServer.cast(pid, {:configure, cortex, neurons, genotype})
  end

  def handle_cast({:configure, cortex, neurons, genotype}, state) do
    state = %{state |
      cortex: cortex,
      neurons: neurons,
      genotype: genotype,
      highest_fitness: 0,
      evaluations: 0,
      total_cycles: 0,
      total_time: 0,
      attempt: 1
    }

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
      evaluations: evaluations
    } = state

    total_cycles = tc + cycles
    total_time = tt + time

    case attempt >= @max_attempts do
      true ->
        %{
          genotype: genotype,
          neurons: neurons
        } = state

        :ok = update_genotype(genotype, exo_self, neurons)

        Registry.dispatch(NN.PubSub, :network_training_complete, fn entries ->
          for {pid, _} <- entries do
            GenServer.cast(pid, {
              :training_complete,
              exo_self,
              highest_fitness,
              evaluations,
              total_cycles,
              total_time,
              genotype
            })
          end
        end)

        {:stop, :normal, state}
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

        state = %{state |
          highest_fitness: highest_fitness,
          total_cycles: total_cycles,
          evaluations: evaluations + 1,
          total_time: total_time,
          attempt: attempt
        }

        Cortex.reactivate(cortex, exo_self)

        {:noreply, state}
    end
  end

  def terminate(_reason, %{cortex: c}) do
    GenServer.stop(c)
  end

  defp update_genotype(genotype, exo_self, [n | neurons]) do
    {^n, id, input_weights} = Neuron.input_weights(n, exo_self)

    weights = input_weights
      |> Enum.map(fn(x) ->
        case x do
          {_pid, weights, eid} -> {eid, weights}
          _ -> x
        end
      end)

    {:ok, element} = Genotype.element(genotype, id)
    element = neuron(element, input_weights: weights)

    Genotype.update(genotype, element)

    update_genotype(genotype, exo_self, neurons)
  end

  defp update_genotype(_genotype, _exo_self, []), do: :ok

end
