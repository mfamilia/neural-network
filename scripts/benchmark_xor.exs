{:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)
{:ok, _} = Registry.register(NN.PubSub, :benchmark_complete, [])

morphology = :xor
hidden_layer_densities = [2]
max_attempts = :infinity
eval_limit = :infinity
fitness_target = 100
total_runs = 100

IO.puts "Benchmark :xor started..."

{:ok, _sut} = NN.Benchmarker.start_link(
  morphology,
  hidden_layer_densities,
  max_attempts,
  eval_limit,
  fitness_target,
  total_runs
)

receive do
  {:"$gen_cast", {
    :benchmark_complete,
    :xor,
    {:fitness, f_min, f_max, f_avg, f_std},
    {:evals, e_min, e_max, e_avg, e_std},
    {:cycles, c_min, c_max, c_avg, c_std},
    {:time, t_min, t_max, t_avg, t_std}
  }} ->
    IO.puts ""
    IO.puts "Benchmark results for :xor"
    IO.puts "Fitness: min[#{f_min}] max[#{f_max}] avg[#{f_avg} std[#{f_std}]]"
    IO.puts "Evaluations: min[#{e_min}] max[#{e_max}] avg[#{e_avg} std[#{e_std}]]"
    IO.puts "Cycles: min[#{c_min}] max[#{c_max}] avg[#{c_avg} std[#{c_std}]]"
    IO.puts "Time: min[#{t_min}] max[#{t_max}] avg[#{t_avg} std[#{t_std}]]"
    IO.puts ""
end
