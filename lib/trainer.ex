defmodule NN.Trainer do
  use GenServer
  alias NN.Constructors.Genotype, as: Genotype
  alias NN.Handlers.Genotype, as: GenotypeHandler
  alias NN.V3.ExoSelf

  @max_attempts 5
  @eval_limit :infinity
  @fitness_target :infinity

  defmodule State do
    defstruct morphology: nil,
      hidden_layer_densities: nil,
      attempts: nil,
      evals: nil,
      fitness_target: nil,
      trainee_name: nil,
      best_trainee_name: nil,
      best_fitness: nil,
      exo_self: nil,
      cycles: nil,
      time: nil,
      genotype_handler: nil,
      result_handler: nil
  end

  def start_link(
    morphology,
    hidden_layer_densities,
    result_handler,
    max_attempts \\ @max_attempts,
    eval_limit \\ @eval_limit,
    fitness_target \\ @fitness_target) do

    state = %State{
      morphology: morphology,
      hidden_layer_densities: hidden_layer_densities,
      attempts: {0, max_attempts},
      evals: {0, eval_limit},
      fitness_target: fitness_target,
      trainee_name: :experimental,
      best_trainee_name: :best,
      best_fitness: 0,
      cycles: 0,
      time: 0,
      genotype_handler: nil,
      result_handler: result_handler
    }

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    configure(self())
    Process.register(self(), :trainer)

    {:ok, state}
  end

  def configure(pid) do
    GenServer.cast(pid, :configure)
  end

  def training_complete(pid, exo_self, fitness, evals, cycles, time) do
    GenServer.cast(pid, {:training_complete, exo_self, fitness, evals, cycles, time})
  end

  def handle_cast(:configure, state) do
    %{
      morphology: m,
      trainee_name: name,
      hidden_layer_densities: hld
    } = state

    {:ok, h} = GenotypeHandler.start_link(name)
    :ok = GenotypeHandler.new(h)
    {:ok, c} = Genotype.start_link(h, m, hld)

    :ok = Genotype.construct(c)

    GenotypeHandler.load(h)

    {:ok, exo_self} = ExoSelf.start_link(h)

    state = %{state | exo_self: exo_self, genotype_handler: h}

    {:noreply, state}
  end

  def handle_cast({
      :training_complete,
      exo_self,
      _fitness,
      _evals,
      _cycles,
      _time
    }, %{
      attempts: {a, max_attempts},
      evals: {e, eval_limit},
      best_fitness: bf,
      fitness_target: ft,
      exo_self: exo_self,
      morphology: m,
      time: time,
      result_handler: h
    } = state)
    when (a >= max_attempts) or (e >= eval_limit) or (bf >= ft) do

    GenServer.cast(h, {:training_complete, self(), m, bf, e, time})

    {:stop, :normal, state}
  end

  def handle_cast({
      :training_complete,
      exo_self,
      fitness,
      evals,
      cycles,
      time
    }, %{
      exo_self: exo_self
    } = state) do

    %{
      evals: {e, eval_limit},
      cycles: c,
      time: t,
      best_fitness: bf,
      genotype_handler: h,
      best_trainee_name: btn,
      attempts: {a, max_attempts}
    } = state

    state = %{state |
      evals: {e + evals, eval_limit},
      cycles: c + cycles,
      time: t + time
    }

    state = case fitness > bf do
      true ->
        GenotypeHandler.save(h, btn)

        %{state |
          attempts: {1, max_attempts},
          best_fitness: fitness
        }
      false ->
        %{state |
          attempts: {a + 1, max_attempts},
          best_fitness: bf
        }
    end

    configure(self())

    {:noreply, state}
  end
end
