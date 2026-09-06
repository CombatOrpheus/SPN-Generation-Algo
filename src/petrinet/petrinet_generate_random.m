function pn = petrinet_generate_random(num_places, num_transitions)
  % PETRINET_GENERATE_RANDOM Generates a connected random Petri Net structure.
  %
  % Inputs:
  %   num_places      - Integer, number of places (P)
  %   num_transitions - Integer, number of transitions (T)
  %
  % Outputs:
  %   pn - Petri net struct with matrix and initial marking

  P = int32(num_places);
  T = int32(num_transitions);
  pn = petrinet_new(P, T);

  remaining_nodes = int32(1:(P + T));

  % Pick initial place and transition
  first_place = randi(P);
  first_trans_node = P + randi(T);

  % Remove them from remaining_nodes
  remaining_nodes(remaining_nodes == first_place | remaining_nodes == first_trans_node) = [];

  % Randomly connect initial pair
  trans_idx = first_trans_node - P;
  if rand() <= 0.5
    % Pre: place -> transition
    pn.matrix(first_place, trans_idx) = 1;
  else
    % Post: transition -> place
    pn.matrix(first_place, trans_idx + T) = 1;
  endif

  % Pre-allocate buffers for subgraph tracking without dynamic re-filtering
  sub_places = zeros(P, 1, "int32");
  sub_transitions = zeros(T, 1, "int32");

  sub_places(1) = first_place;
  num_sub_places = 1;

  sub_transitions(1) = first_trans_node;
  num_sub_transitions = 1;

  % Shuffle remaining nodes
  perm = randperm(length(remaining_nodes));
  remaining_nodes = remaining_nodes(perm);

  % Iteratively connect each remaining node to the existing subgraph
  for i = 1:length(remaining_nodes)
    node = remaining_nodes(i);

    if node <= P
      place = node;
      chosen_trans_node = sub_transitions(randi(num_sub_transitions));
      trans_idx = chosen_trans_node - P;

      num_sub_places = num_sub_places + 1;
      sub_places(num_sub_places) = node;
    else
      place = sub_places(randi(num_sub_places));
      trans_idx = node - P;

      num_sub_transitions = num_sub_transitions + 1;
      sub_transitions(num_sub_transitions) = node;
    endif

    if rand() <= 0.5
      pn.matrix(place, trans_idx) = 1;
    else
      pn.matrix(place, trans_idx + T) = 1;
    endif
  endfor

  % Place 1 token on a random place
  random_place = randi(P);
  pn.matrix(random_place, 2 * T + 1) = 1;
  pn.initial_marking = pn.matrix(:, 2 * T + 1);
endfunction
