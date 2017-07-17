defmodule NN.Trainer do
  use GenServer
  alias NN.Constructors.Genotype, as: Genotype
  alias NN.Handlers.Genotype, as: Handler
  alias NN.V3.ExoSelf

  @max_attempts 5
  @eval_limit :infinity
  @fitness_target :infinity
  @io %{puts: &IO.puts/1}

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
      handler: nil,
      io: nil
  end

  def start_link(
    morphology,
    hidden_layer_densities,
    max_attempts \\ @max_attempts,
    eval_limit \\ @eval_limit,
    fitness_target \\ @fitness_target,
    io \\ @io) do

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
      handler: nil,
      io: io
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
      hidden_layer_densities: hld,
      io: io
    } = state

    {:ok, h} = Handler.start_link(name, io)
    :ok = Handler.new(h)
    {:ok, c} = Genotype.start_link(h, m, hld)

    :ok = Genotype.construct(c)

    Handler.load(h)

    {:ok, exo_self} = ExoSelf.start_link(h)

    state = %{state | exo_self: exo_self, handler: h}

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
      exo_self: exo_self
    } = state)
    when (a >= max_attempts) or (e >= eval_limit) or (bf >= ft) do

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
      handler: h,
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
        Handler.save(h, btn)

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

  def terminate(:normal, state) do
    %{
      io: io,
      handler: h,
      morphology: m,
      best_fitness: bf,
      evals: {e, _},
      time: time
    } = state

    Handler.print(h)

    io.puts.("Morphology: #{m} | Best Fitness: #{bf} | Evaluations: #{e} | Time; #{time}")

    {:ok, state}
  end
end

