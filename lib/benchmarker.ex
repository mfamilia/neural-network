defmodule NN.Benchmarker do
  use GenServer

  alias NN.Trainer

  @max_attempts 5
  @eval_limit :infinity
  @fitness_target :infinity
  @total_runs 100

  defmodule State do
    defstruct morphology: nil,
              hidden_layer_densities: nil,
              max_attempts: nil,
              eval_limit: nil,
              fitness_target: nil,
              fitness: nil,
              total_runs: nil,
              evals: nil,
              runs: nil,
              cycles: nil,
              time: nil
  end

  def start_link(
        morphology,
        hidden_layer_densities,
        max_attempts \\ @max_attempts,
        eval_limit \\ @eval_limit,
        fitness_target \\ @fitness_target,
        total_runs \\ @total_runs
      ) do
    state = %State{
      morphology: morphology,
      hidden_layer_densities: hidden_layer_densities,
      max_attempts: max_attempts,
      eval_limit: eval_limit,
      fitness_target: fitness_target,
      total_runs: total_runs,
      runs: 0,
      evals: [],
      fitness: [],
      cycles: [],
      time: []
    }

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, _} = Registry.register(NN.PubSub, :trainer_training_complete, [])

    benchmark(state)

    {:ok, state}
  end

  def handle_cast({:training_complete, fitness, evals, cycles, time, _genotype}, state) do
    %{
      runs: runs,
      total_runs: total_runs,
      fitness: f,
      evals: e,
      cycles: c,
      time: t
    } = state

    state = %{
      state
      | fitness: [fitness | f],
        evals: [evals | e],
        cycles: [cycles | c],
        time: [time | t]
    }

    case runs >= total_runs do
      true -> report_benchmark(state)
      false -> continue_benchmarking(state)
    end
  end

  defp continue_benchmarking(state) do
    %{runs: runs} = state
    state = %{state | runs: runs + 1}

    benchmark(state)

    {:noreply, state}
  end

  defp report_benchmark(state) do
    %{
      fitness: f,
      time: t,
      cycles: c,
      evals: e,
      morphology: m
    } = state

    fitness = calculate_stats(:fitness, f)
    time = calculate_stats(:time, t)
    cycles = calculate_stats(:cycles, c)
    evals = calculate_stats(:evals, e)

    Registry.dispatch(NN.PubSub, :benchmark_complete, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, {
          :benchmark_complete,
          m,
          fitness,
          evals,
          cycles,
          time
        })
      end
    end)

    {:stop, :normal, state}
  end

  defp benchmark(state) do
    %{
      morphology: m,
      hidden_layer_densities: hld,
      max_attempts: a,
      eval_limit: e,
      fitness_target: f
    } = state

    {:ok, _} = Trainer.start_link(m, hld, a, e, f)
  end

  defp calculate_stats(key, list) do
    calculate_stats(key, list, list)
  end

  defp calculate_stats(key, list, list, sum \\ 0, count \\ 0, min \\ :infinity, max \\ 0)

  defp calculate_stats(key, [], list, sum, count, min, max) do
    avg = sum / count

    {key, min, max, avg, std(list, avg)}
  end

  defp calculate_stats(key, [head | tail], list, sum, count, min, max) do
    min = if head < min, do: head, else: min
    max = if head > max, do: head, else: max

    calculate_stats(key, tail, list, sum + head, count + 1, min, max)
  end

  defp std(list, avg, sum \\ 0, count \\ 0)

  defp std([], _avg, sum, count) do
    :math.sqrt(sum / count)
  end

  defp std([head | tail], avg, sum, count) do
    std(tail, avg, sum + :math.pow(avg - head, 2), count + 1)
  end
end
