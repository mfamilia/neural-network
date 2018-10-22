defmodule Random do
  def seed do
    {x, y, z} = :erlang.timestamp()

    :rand.seed(:exs1024s, {x, y, z})
  end

  def uniform do
    :rand.uniform()
  end
end
