import IEx.Helpers

{:ok, _} = Registry.start_link(keys: :unique, name: NN.PubSub)
{:ok, _} = Registry.register(NN.PubSub, :polis_updates, [])

alias NN.V4.Polis

IO.puts "Creating Polis..."
:ok = Polis.create

IO.puts "Staring Polis..."
{:ok, _} = Polis.start

receive do
  {:"$gen_cast", {
    :polis_online,
  }} ->
    IO.puts ""
    IO.puts "Polis is online."
    IO.puts ""
end

IO.puts "Stopping Polis..."
:ok = Polis.stop()

receive do
  {:"$gen_cast", {
    :polis_offline,
  }} ->
    IO.puts ""
    IO.puts "Polis is offline."
    IO.puts ""
end
