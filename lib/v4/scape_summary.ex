defmodule NN.V4.ScapeSummary do
  require Record

  Record.defrecord(:scape_summary,
    address: nil,
    parameters: nil,
    type: nil
  )
end
