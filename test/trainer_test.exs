defmodule NN.TrainerTest do
  use ExUnit.Case
  alias NN.Trainer

  setup do
    self = self()
    io = %{puts: fn(msg) -> send(self, {:puts, msg}) end}
    morphology = :xor
    hidden_layer_densities = [2]
    max_attempts = :infinity
    eval_limit = :infinity
    fitness_target = 99

    {:ok, sut} = Trainer.start_link(
      morphology,
      hidden_layer_densities,
      max_attempts,
      eval_limit,
      fitness_target)

    [sut: sut]
  end

  test "configure", %{sut: sut} do
    Process.sleep(50)
  end
end
