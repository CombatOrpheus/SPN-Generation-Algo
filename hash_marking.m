%% key = hash_marking(marking)
%%
%% Computes a numerical hash of a marking vector.
%%
%% This function implements a simple weighted sum hash to convert a marking
%% vector into a single numerical key. This is significantly faster than
%% converting the vector to a string, which is a major performance bottleneck
%% in the reachability graph computation.
%%
%% The weights are chosen to be prime numbers to minimize the likelihood of
%% collisions, where different markings produce the same hash. While not
%% perfect, this approach is a good trade-off between speed and accuracy.
%%
%% Inputs:
%%   marking: A column vector representing the marking of the SPN.
%%
%% Outputs:
%%   key: A numerical hash value of the marking.

function key = hash_marking(marking)
  persistent weights;
  num_elements = numel(marking);

  if isempty(weights) || numel(weights) < num_elements
    new_size = max(num_elements, 200);
    limit = new_size * 15; % Estimate a limit to get enough primes
    p = primes(limit);
    while numel(p) < new_size
      limit = limit * 2;
      p = primes(limit);
    end
    weights = p(1:new_size)';
  endif

  if num_elements > numel(weights)
    new_size = num_elements + 100;
    limit = new_size * 15;
    p = primes(limit);
    while numel(p) < new_size
      limit = limit * 2;
      p = primes(limit);
    end
    weights = p(1:new_size)';
  endif

  key = dot(marking, weights(1:num_elements));
endfunction
