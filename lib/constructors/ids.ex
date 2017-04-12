defmodule NN.Constructors.Ids do
  def generate_ids(0, acc) do
    acc
  end

  def generate_ids(index, acc) do
    id = generate_id()

    generate_ids(index-1, [id | acc])
  end

  def generate_id do
    UUID.uuid4
  end
end
