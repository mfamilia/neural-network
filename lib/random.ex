defmodule Random do
  def seed do
    {x, y, z} = :erlang.now()

    :random.seed(x, y, z)
  end

  def uniform do
    :random.uniform
  end
end
