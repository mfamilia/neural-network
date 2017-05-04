alias NN.Handlers.Genotype, as: Handler
alias NN.Constructors.Genotype

file_name = "./test/fixtures/genotypes/simple.nn"
{:ok, h} = Handler.start_link(file_name)

Handler.new(h)

{:ok, c} = Genotype.start_link(h, :random, :print_results, [1, 3])
Genotype.construct(c)

