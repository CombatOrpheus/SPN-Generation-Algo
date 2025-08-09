%% [mark_density, mu_values] = calculate_average_markings(v_list, steady_state_probabilities)
%%
%% Calculates the average number of tokens (mu) for each place at steady state.
%%
%% It also computes the marking density, which is the probability of finding a
%% certain number of tokens in a given place.
%%
%% NOTE: This function was originally named `average_marks_number`.
%%
%% Inputs:
%%   v_list: The list of reachable markings (states).
%%   steady_state_probabilities: The steady-state probability for each marking.
%%
%% Outputs:
%%   mark_density: A matrix where mark_density(i, j) is the probability of
%%                 having j-1 tokens in place i.
%%   mu_values: A vector containing the average number of tokens for each place.

function [mark_density, mu_values] = calculate_average_markings(v_list, steady_state_probabilities)
  num_places = rows(v_list);

  % Find the range of token values across all places and markings.
  max_token_value = max(v_list(:));
  token_values = (0:max_token_value)'; % A column vector [0, 1, 2, ...]

  mark_density = zeros(num_places, length(token_values));

  % For each place, calculate the probability distribution of its token count.
  for p_idx = 1:num_places
    place_markings = v_list(p_idx, :); % Token counts for this place in all markings.

    % For each possible token count, sum the probabilities of the markings
    % where the place has that token count.
    for t_val = 0:max_token_value
      markings_with_t_val = find(place_markings == t_val);
      if ~isempty(markings_with_t_val)
        mark_density(p_idx, t_val + 1) = sum(steady_state_probabilities(markings_with_t_val));
      endif
    endfor
  endfor

  % The average number of tokens (mu) for each place is the expected value of its
  % token distribution.
  mu_values = mark_density * double(token_values);
endfunction
