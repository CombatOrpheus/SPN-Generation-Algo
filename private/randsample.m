%% samples = randsample(population, k)
%%
%% Selects a random sample of k elements from a population vector.
%%
%% This is a simplified implementation of the `randsample` function from the
%% statistics package, created to avoid external dependencies. It works by
%% shuffling the population and taking the first k elements.
%%
%% NOTE: This implementation does not support sampling with replacement.
%%
%% Inputs:
%%   population: A vector of elements to sample from.
%%   k: The number of samples to draw.
%%
%% Outputs:
%%   samples: A vector containing k unique elements chosen randomly from the
%%            population.

function samples = randsample(population, k)
  % Ensure k is not larger than the number of elements available.
  if k > numel(population)
    error('k cannot be greater than the number of elements in the population.');
  endif

  % Shuffle the population vector randomly.
  shuffled = population(randperm(length(population)));

  % Take the first k elements from the shuffled vector.
  samples = shuffled(1:k);
endfunction
