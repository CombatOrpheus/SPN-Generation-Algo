%% choice = random_choice(vector)
%%
%% This function chooses a random element from a vector.
%%
%% It is a simple helper to abstract the process of picking a random value
%% from a list of items.
%%
%% Inputs:
%%   vector: A vector of numbers from which to choose.
%%
%% Outputs:
%%   choice: A single element chosen randomly from the input vector.

function choice = random_choice(vector)
  % randi(n) generates a random integer between 1 and n.
  % numel(vector) gives the number of elements in the vector.
  random_index = randi(numel(vector));
  choice = vector(random_index);
endfunction
