defmodule NN.Scape do
  import String

  def start_link(exo_self, type) do
    scape_type = to_string(type)
    module_name = "Elixir.NN.Scapes.#{String.capitalize(scape_type)}"
    module = to_existing_atom(module_name)

    apply(module, :start_link, [exo_self])
  end

  def sense(exo_self, scape) do
    GenServer.call(scape, {exo_self, :sense})
  end

  def action(exo_self, scape, output) do
    GenServer.call(scape, {exo_self, :action, output})
  end
end
