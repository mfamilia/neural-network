defmodule NN.BenchmarkerTest do
  use ExUnit.Case
  alias NN.Benchmarker

  setup do
    {:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)
    {:ok, _} = Registry.register(NN.PubSub, :benchmark_complete, [])

    morphology = :xor
    hidden_layer_densities = [2]
    max_attempts = :infinity
    eval_limit = :infinity
    fitness_target = 100
    total_runs = 2

    {:ok, sut} =
      Benchmarker.start_link(
        morphology,
        hidden_layer_densities,
        max_attempts,
        eval_limit,
        fitness_target,
        total_runs
      )

    [sut: sut]
  end

  test "benchmark complete" do
    assert_receive {:"$gen_cast",
                    {
                      :benchmark_complete,
                      :xor,
                      {:fitness, _, _, _, _},
                      {:evals, _, _, _, _},
                      {:cycles, _, _, _, _},
                      {:time, _, _, _, _}
                    }},
                   1_000
  end
end
