%% choice = random_choice(vector)
%%
%% Selects a single random element from a given vector.
%%
%% This is a simple utility function that abstracts the process of picking one
%% random value from a list of items. It is equivalent to sampling one element
%% without replacement.
%%
%% Inputs:
%%   vector: A vector of any size containing the population of elements from
%%           which to choose.
%%
%% Outputs:
%%   choice: A single scalar element chosen uniformly at random from the input
%%           `vector`.

function choice = random_choice(vector)
  % randi(n) generates a random integer between 1 and n.
  % numel(vector) gives the number of elements in the vector.
  random_index = randi(numel(vector));
  choice = vector(random_index);
endfunction