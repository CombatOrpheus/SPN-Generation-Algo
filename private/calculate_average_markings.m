%% [mark_density, mu_values] = calculate_average_markings(v_list, steady_state_probabilities)
%%
%% Calculates the average number of tokens (mu) for each place at steady state.
%%
%% This function computes two key metrics based on the steady-state probability
%% distribution of a Petri net's markings. It provides insight into the long-term
%% behavior of the system.
%%
%% 1. Marking Density: For each place, this is the probability of finding a
%%    specific number of tokens (e.g., P(place 'i' has 'k' tokens)). This is
%%    returned as a matrix.
%%
%% 2. Average Token Count (Mu): For each place, this is the expected number of
%%    tokens at steady state. It is calculated from the marking density.
%%
%% This implementation is vectorized for performance, using `accumarray` to
%% avoid explicit loops over markings, which can be very slow in Octave.
%%
%% Inputs:
%%   v_list: The list of all reachable markings (states) of the SPN. This is a
%%           matrix where each column corresponds to a unique marking vector.
%%
%%   steady_state_probabilities: A column vector containing the steady-state
%%                               probability for each corresponding marking in
%%                               `v_list`. The sum of this vector should be 1.
%%
%% Outputs:
%%   mark_density: A matrix of size [num_places, max_tokens + 1] where
%%                 `mark_density(i, j)` holds the probability of having `j-1`
%%                 tokens in place `i` at steady state.
%%
%%   mu_values: A column vector of size [num_places, 1] containing the average
%%              number of tokens (mu) for each place.

function [mark_density, mu_values] = calculate_average_markings(v_list, steady_state_probabilities)
  [num_places, num_markings] = size(v_list);

  % If there are no markings, return empty results.
  if num_markings == 0
    mark_density = [];
    mu_values = [];
    return;
  endif

  max_token_value = max(v_list(:));

  % --- Vectorized calculation of marking density ---
  % We use accumarray to avoid loops. It's a powerful tool for this kind of task.

  % 1. Create the subscripts for accumarray.
  % The output is a (num_places x max_token_value+1) matrix.
  % Each entry (p, t) should sum the probabilities of all markings where place 'p' has 't-1' tokens.
  % The first subscript column will be the place index.
  place_indices = repmat((1:num_places)', 1, num_markings);
  % The second subscript column will be the token count + 1 (for 1-based indexing).
  token_counts = v_list + 1;
  % Combine them into a single list of [row, col] subscripts.
  subs = [place_indices(:), token_counts(:)];

  % 2. Create the values to be accumulated.
  % These are the steady-state probabilities, repeated for each place.
  prob_vals = repmat(steady_state_probabilities', num_places, 1);

  % 3. Call accumarray.
  output_size = [num_places, max_token_value + 1];
  mark_density = accumarray(subs, prob_vals(:), output_size, @sum, 0);

  % --- Calculate the average number of tokens (mu) ---
  % This is the expected value of the token distribution for each place.
  token_values = (0:max_token_value)';
  mu_values = mark_density * double(token_values);
endfunction