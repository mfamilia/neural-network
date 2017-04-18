file_name = "./test/fixtures/genotypes/simple.nn"
{:ok, handler} = NN.Handlers.GenotypeFile.start_link(file_name)
{:ok, constructor} = NN.Constructors.Genotype.start_link(handler, :random, :print_results, [1, 3])
NN.Constructors.Genotype.construct_genotype(constructor)

