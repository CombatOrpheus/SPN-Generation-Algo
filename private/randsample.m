%% samples = randsample(population, k)
%%
%% Selects a random sample of k unique elements from a population vector.
%%
%% This function provides a simplified implementation of the `randsample`
%% function found in Octave's statistics package, created to avoid requiring
%% that package as a dependency. It works by performing sampling without
%% replacement.
%%
%% The method used is to randomly shuffle the entire population vector and then
%% simply take the first `k` elements from the shuffled result.
%%
%% NOTE: This implementation does not support sampling with replacement.
%%
%% Inputs:
%%   population: A vector containing the set of elements to sample from.
%%   k: An integer specifying the number of unique samples to draw. This
%%      value cannot be larger than the number of elements in the population.
%%
%% Outputs:
%%   samples: A vector of length `k` containing unique elements chosen
%%            randomly from the `population`.

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