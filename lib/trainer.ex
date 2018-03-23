defmodule NN.Trainer do
  use GenServer
  alias NN.Constructors.Genotype, as: GenotypeContructor
  alias NN.Constructors.Phenotype

  @max_attempts 5
  @eval_limit :infinity
  @fitness_target :infinity

  defmodule State do
    defstruct morphology: nil,
      hidden_layer_densities: nil,
      attempts: nil,
      evals: nil,
      fitness_target: nil,
      best_fitness: nil,
      cycles: nil,
      time: nil,
      genotype: nil
  end

  def start_link(
    morphology,
    hidden_layer_densities,
    max_attempts \\ @max_attempts,
    eval_limit \\ @eval_limit,
    fitness_target \\ @fitness_target) do

    state = %State{
      morphology: morphology,
      hidden_layer_densities: hidden_layer_densities,
      attempts: {0, max_attempts},
      evals: {0, eval_limit},
      fitness_target: fitness_target,
      best_fitness: 0,
      cycles: 0,
      time: 0,
      genotype: nil
    }

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, _} = Registry.register(NN.PubSub, :network_training_complete, [])

    train(state)

    {:ok, state}
  end

  def training_complete(pid, exo_self, fitness, evals, cycles, time, genotype) do
    GenServer.cast(pid, {:training_complete, exo_self, fitness, evals, cycles, time, genotype})
  end

  def handle_cast({
      :training_complete,
      _exo_self,
      fitness,
      evals,
      cycles,
      time,
      genotype
    }, state) do

    %{
      evals: {e, eval_limit},
      cycles: c,
      time: t,
      best_fitness: bf,
      attempts: {a, max_attempts},
      genotype: g
    } = state

    state = %{state |
      evals: {e + evals, eval_limit},
      cycles: c + cycles,
      time: t + time
    }

    has_improved = fitness > bf
    state = case has_improved do
      true ->
        if g, do: GenServer.stop(g)

        %{state |
          attempts: {1, max_attempts},
          best_fitness: fitness,
          genotype: genotype
        }
      false ->
        %{state |
          attempts: {a + 1, max_attempts},
          best_fitness: bf
        }
    end

    case state do
      %{
        attempts: {a, max_attempts},
        evals: {e, eval_limit},
        best_fitness: bf,
        fitness_target: ft
      } when (a >= max_attempts) or (e >= eval_limit) or (bf >= ft)
        -> report(state)
      _ -> train(state)
    end
  end

  defp report(state) do
    %{
      cycles: c,
      evals: {e, _eval_limit},
      best_fitness: bf,
      time: time,
      genotype: g
    } = state

    Registry.dispatch(NN.PubSub, :trainer_training_complete, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, {
          :training_complete,
          bf,
          e,
          c,
          time,
          g
        })
      end
    end)

    {:stop, :normal, state}
  end

  defp train(state) do
    %{
      morphology: m,
      hidden_layer_densities: hld
    } = state

    {:ok, genotype} = GenotypeContructor.construct(m, hld)
    {:ok, _exo_self} = Phenotype.construct(genotype)

    {:noreply, state}
  end
end
