defmodule NN.TrainerTest do
  use ExUnit.Case
  alias NN.Trainer

  setup do
    {:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)
    {:ok, _} = Registry.register(NN.PubSub, :trainer_training_complete, [])

    morphology = :xor
    hidden_layer_densities = [2]
    max_attempts = :infinity
    eval_limit = :infinity
    fitness_target = 99

    {:ok, sut} =
      Trainer.start_link(
        morphology,
        hidden_layer_densities,
        max_attempts,
        eval_limit,
        fitness_target
      )

    [sut: sut]
  end

  test "training complete" do
    assert_receive {:"$gen_cast",
                    {
                      :training_complete,
                      best_fitness,
                      evals,
                      attempts,
                      time,
                      genotype
                    }},
                   1_000

    assert best_fitness > 0
    assert evals > 0
    assert attempts > 0
    assert time > 0
    assert Process.alive?(genotype)
  end
end
