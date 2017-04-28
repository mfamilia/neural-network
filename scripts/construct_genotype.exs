alias NN.Handlers.Genotype, as: Handler
alias NN.Constructors.Genotype, as: Constructor

file_name = "./test/fixtures/genotypes/simple.nn"
{:ok, handler} = Handler.start_link(file_name)

Handler.new(handler)

{:ok, constructor} = Constructor.start_link(handler, :random, :print_results, [1, 3])
Constructor.construct_genotype(constructor)

