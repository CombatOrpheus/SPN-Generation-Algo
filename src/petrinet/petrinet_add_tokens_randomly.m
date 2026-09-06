function pn = petrinet_add_tokens_randomly(pn)
  % PETRINET_ADD_TOKENS_RANDOMLY Vectorized addition of tokens to places.
  %
  % Adds 1 token to each place with 30% probability without interpreted loops.

  P = pn.places;
  T = pn.transitions;
  m0_col = 2 * T + 1;

  % Vectorized addition: rand(P, 1) <= 0.3 generates a boolean mask
  pn.matrix(:, m0_col) = pn.matrix(:, m0_col) + int32(rand(P, 1) <= 0.3);
  pn.initial_marking = pn.matrix(:, m0_col);
endfunction
