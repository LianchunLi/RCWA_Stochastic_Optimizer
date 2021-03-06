close all
clear
%% generate dielectric distributions

num_layers = 2;
c0=3e8;
num_wavelengths = 100;
lambda_scan = linspace(1.0, 1.6, num_wavelengths);
w_scan = 2*pi*c0./lambda_scan*1e6;
theta = 0; % angle of incidence
lattice_constant = 1;

%% =================== construct tensor volumes =========================%%
silicon = 12*ones(1, num_wavelengths);
air = 1*ones(1, num_wavelengths);
glass = 3*ones(1, num_wavelengths);

silicon = construct_tensor_volume(silicon);
air = construct_tensor_volume(air);
glass = construct_tensor_volume(glass);

% need to create a layer repository
layer1 = {silicon, silicon}; % NOTE EVEN IF A LAYER IS UNIFORM, NEED 2 specs
layer2 = {glass, glass};

%% generate candidate structures to generate your population
structure1 = {layer1, layer2, layer1, layer2, layer1}; %stack of layers
% structure2 = {layer2, layer1, layer1, layer2};
% structure3 = {layer1, layer2, layer2, layer1};
dielectric_tensors_list = {layer1, layer2};
max_layers_in_struct = 10;
min_layers_in_struct = 4;
num_samples = 400;
layer_dielectric_tensor_distribution = generate_dielectric_layers(num_samples,...
    min_layers_in_struct, max_layers_in_struct, dielectric_tensors_list);


%% structure specs
scaling = 1/2;

%% specify parameters of the population and the genetic evolution
num_individuals = 100; %always specify num_individuals to be divisible by 4
epochs = 100;
selection_rate = 1; %1 indicates only individuals from the top half are taken
mutation_rate = 0.1;

%% initialize population
thickness_range = [0.05, 0.6];
%layer_dielectric_tensor_distribution = {structure1, structure2, structure3};
layer_structure_distribution = {scaling*[1,1]}; %% EVERYTHING IS UNIFORM;

population = population_initializer(num_individuals,...
    lattice_constant, thickness_range, ...
    layer_dielectric_tensor_distribution, layer_structure_distribution);


%% specify and plot the desired spectra for (Reflection)
desired_reflection = ones(1,length(lambda_scan));
desired_reflection(round(length(lambda_scan)/2):end) = 0;
fig = figure();
plot(lambda_scan, desired_reflection, 'linewidth', 2)
drawnow()
hold on;

%% specify parameters of the simulation
lattice_constant = 1; %microns
num_ord = 1;
e = [1,1];

%% =======================================================================%%
% beyond this point, the code should take care of itself


%% run epochs
best_individuals = cell(1);
fitness_history = [];

for t = 1:epochs
    disp(strcat('EPOCH: ', num2str(t)));
    
    % at every epoch, simulate the population
    immature_population = population.immature_population;
    maturized_population = cell(1);
    
    best_individual = 0; bestFitness = -1e8;
    %% ======================= fitness evaluation cell ===================%
    for i = 1:length(immature_population)
        % simulate each individual in the population (special function)
        individual = immature_population{i};
        [Ref, Tran] = simulate_structure_anisotropic(individual, ...
        lambda_scan, theta, num_ord, e);
        %convert Reflection and Transmission to a fitness
        individual.Fitness = evaluate_fitness(Ref, desired_reflection);
        if(individual.Fitness > bestFitness)
           best_individual = individual;
           bestFitness = individual.Fitness
        end
        %add individual to mature section
        maturized_population{i} = individual; 
        disp(strcat('Individual #',num2str(i), ' simulated'));
    end
    
    %% PERFORM A LINE SEARCH AFTER EVALUATING THE NEW INDIVIDUALS
    layered_structure_instance = best_individual;
    optimized_individuals = line_search_individual(layered_structure_instance, ...
    lambda_scan, theta, num_ord, e, desired_reflection);
    
    %% plot a Ref...
    plot(lambda_scan, Ref);drawnow();
    
    %once we are done, we should delete the immature population to make it
    %ready accept the next generation
    population.immature_population = cell(1);
    
    % remember, we want to APPEND the new individuals simulated
    if(isempty(optimized_individuals)>0)
        population.mature_population = ...
            [population.mature_population; maturized_population.'; optimized_individuals.'];
    else
        population.mature_population = ...
            [population.mature_population; maturized_population.'];       
    end
    %% ===================== selection cell =============================%%
    % now that every individual has a fitness, perform selection
    [reduced_population, max_individual, fitnesses] = ...
        selection(population.mature_population, selection_rate);
    best_individuals{t} = max_individual;
    fitness_history= [fitness_history; mean(fitnesses), max(fitnesses)]
    % after selection, perform mating
    
    population.mature_population = reduced_population.';
    
    %% ================== mating cell ===================================%%
    offspring = mate_population(population.mature_population);
    
    %% ================== mutation cell ================================%%
    offspring = mutate_population(offspring, mutation_rate);
    
    %% ================== enforce constraints ===========================%%
    % sometimes, you do not wan the structure to follow some particular
    % constraings, like maximum number of layers possible...
    offspring = max_layers(offspring, 10);
    
    %% ==============add the new offspring to the population =============%%
    population.immature_population = offspring;

    % perform mutations on the matured population and ADD them to the
    % immature (MAYBE, this isn't representative of reproductive mutation)
    
    disp(strcat('best_fitness at epoch #', num2str(t), ': ',' ',  ...
        num2str(max_individual.Fitness)));
    disp(strcat('pop_mature: ', num2str(length(population.mature_population)), ...
        ' pop_immature: ', num2str(length(population.immature_population))));
    
end

