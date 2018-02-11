defmodule NN.TrainerTest do
  use ExUnit.Case
  alias NN.Trainer

  setup do
    morphology = :xor
    hidden_layer_densities = [2]
    max_attempts = :infinity
    eval_limit = :infinity
    fitness_target = 99

    {:ok, sut} = Trainer.start_link(
      morphology,
      hidden_layer_densities,
      self(),
      max_attempts,
      eval_limit,
      fitness_target)

    [sut: sut]
  end

  test "training complete", %{sut: sut} do
    assert_receive {:"$gen_cast", {:training_complete, ^sut, :xor, best_fitness, evals, time}}, 5_000

    assert best_fitness > 188
    assert evals > 100
    assert time > 1000
  end
end
