%% choice = random_choice(vector)
%%
%% Selects a random element from a given vector.
%%
%% This is a simple helper function to abstract the process of picking one
%% element from a list of items.
%%
%% Inputs:
%%   vector: A vector of any type.
%%
%% Output:
%%   choice: A single element chosen randomly from the input vector.

function choice = random_choice(vector)
  if isempty(vector)
    error("Cannot choose from an empty vector.");
  endif
  choice = vector(randi(numel(vector)));
endfunction