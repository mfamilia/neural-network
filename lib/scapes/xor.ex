defmodule NN.Scapes.Xor do
  use GenServer

  @xor [{[-1, -1], [-1]}, {[1, -1], [1]}, {[-1, 1], [1]}, {[1, 1], [-1]}]

  defmodule State do
    defstruct exo_self: nil,
              xor: nil,
              total_error: nil
  end

  def start_link(exo_self) do
    GenServer.start_link(__MODULE__, exo_self)
  end

  def init(exo_self) do
    state = %State{
      exo_self: exo_self,
      xor: @xor,
      total_error: 0
    }

    {:ok, state}
  end

  def handle_call({exo_self, :sense}, _from, %{exo_self: exo_self} = state) do
    %{xor: [{input, _correct_output} | _xor]} = state

    {:reply, {:percept, input}, state}
  end

  def handle_call(
        {exo_self, :action, output},
        _from,
        %{exo_self: exo_self, xor: [{_input, correct_output}]} = state
      ) do
    %{total_error: total_error} = state

    error = list_compare(output, correct_output, 0)

    fitness = total_fitness(total_error + error)
    halt_flag = 1

    state = %{state | xor: @xor, total_error: 0}

    {:reply, {:fitness, fitness, halt_flag}, state}
  end

  def handle_call({exo_self, :action, output}, _from, %{exo_self: exo_self} = state) do
    %{
      xor: [{_input, correct_output} | xor],
      total_error: total_error
    } = state

    error = list_compare(output, correct_output, 0)

    state = %{state | xor: xor, total_error: total_error + error}

    fitness = 0
    halt_flag = 0

    {:reply, {:fitness, fitness, halt_flag}, state}
  end

  defp list_compare([x | output], [y | correct_output], total_error) do
    list_compare(output, correct_output, total_error + :math.pow(x - y, 2))
  end

  defp list_compare([], [], total_error) do
    :math.sqrt(total_error)
  end

  defp total_fitness(total_error) do
    1 / (:math.sqrt(total_error) + 0.00001)
  end
end
