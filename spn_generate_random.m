%% [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
%%
%% Generates a random, connected Stochastic Petri Net (SPN).
%%
%% The function constructs an SPN by first ensuring a connected graph of places
%% and transitions. This guarantees that the resulting Petri net is not disjoint,
%% meaning there are no isolated components. It starts by connecting a random
%% place and transition, then iteratively adds the remaining nodes, ensuring each
%% new node is connected to the existing subgraph.
%%
%% After establishing this connected base, the function adds further random
%% connections between places and transitions based on a given probability,
%% increasing the complexity of the net's structure.
%%
%% The function also initializes the net with a random marking and assigns
%% random integer firing rates (lambdas) to each transition. Note that this
%% function does not guarantee the liveness or boundedness of the generated SPN;
%% those properties must be checked by a separate filter function.
%%
%% Inputs:
%%   pn: An integer specifying the number of places in the net.
%%   tn: An integer specifying the number of transitions in the net.
%%   prob: A probability (scalar from 0 to 1) of adding an extra random
%%         connection between any place and transition. A higher value leads
%%         to a denser net.
%%   max_lambda: An integer specifying the maximum value for the transition
%%               firing rates (lambda). The rates are chosen uniformly from
%%               the integer range [1, max_lambda].
%%
%% Outputs:
%%   cm: The compound matrix representing the generated SPN. This is a
%%       pn x (2*tn + 1) integer matrix with the following structure:
%%       - Columns 1 to tn: The pre-incidence matrix (T_in or A-), indicating
%%         inputs to transitions.
%%       - Columns (tn + 1) to 2*tn: The post-incidence matrix (T_out or A+),
%%         indicating outputs from transitions.
%%       - Column (2*tn + 1): The initial marking (M0) of the net.
%%
%%   lambda: A column vector of size tn x 1, containing the randomly generated
%%           firing rate (lambda) for each transition.

function [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
  % Pre-allocate the compound matrix with zeros.
  cm = zeros(pn, 2 * tn + 1, "int32");

  % --- Build a connected graph ---
  % To avoid disconnected components, we ensure that every place and transition
  % is part of a single connected graph. We use logical flags to track which
  % nodes have been added to the graph, which is more memory-efficient than
  % managing lists of nodes.

  % Logical flags to track connected nodes.
  places_in_graph = false(pn, 1);
  transitions_in_graph = false(tn, 1);

  % A list of all node indices for random permutation.
  all_nodes = [1:(pn + tn)]';
  shuffled_nodes = all_nodes(randperm(pn + tn));

  % Start with the first random node from the shuffled list.
  start_node_idx = shuffled_nodes(1);

  if start_node_idx <= pn
    % If the first node is a place, connect it to a random transition.
    start_place = start_node_idx;
    start_transition = randi(tn);
    places_in_graph(start_place) = true;
    transitions_in_graph(start_transition) = true;
  else
    % If the first node is a transition, connect it to a random place.
    start_place = randi(pn);
    start_transition = start_node_idx - pn;
    places_in_graph(start_place) = true;
    transitions_in_graph(start_transition) = true;
  endif

  % Pre-generate random numbers to avoid calling rand() inside the loop.
  rand_directions = rand(pn + tn, 1);
  rand_indices = rand(pn + tn, 1);

  % Create a random connection (place -> transition or transition -> place).
  if rand_directions(1) <= 0.5
    cm(start_place, start_transition) = 1;
  else
    cm(start_place, tn + start_transition) = 1;
  endif

  % Iteratively connect the remaining nodes.
  for i = 2:(pn + tn)
    node = shuffled_nodes(i);

    if node <= pn % The current node is a place.
      if places_in_graph(node)
        continue; % Skip if already in the graph.
      endif

      % Connect this new place to a random, existing transition.
      places_in_graph(node) = true;
      connected_transition_idx = find(transitions_in_graph);
      rand_idx = floor(rand_indices(i) * numel(connected_transition_idx)) + 1;
      random_transition = connected_transition_idx(rand_idx);

      if rand_directions(i) <= 0.5
        cm(node, random_transition) = 1;
      else
        cm(node, tn + random_transition) = 1;
      endif
    else % The current node is a transition.
      transition_idx = node - pn;
      if transitions_in_graph(transition_idx)
        continue; % Skip if already in the graph.
      endif

      % Connect this new transition to a random, existing place.
      transitions_in_graph(transition_idx) = true;
      connected_place_idx = find(places_in_graph);
      rand_idx = floor(rand_indices(i) * numel(connected_place_idx)) + 1;
      random_place = connected_place_idx(rand_idx);

      if rand_directions(i) <= 0.5
        cm(random_place, transition_idx) = 1;
      else
        cm(random_place, tn + transition_idx) = 1;
      endif
    endif
  endfor

  % --- Add more connections based on probability ---
  % To increase the net's complexity, we add more connections with a given
  % probability. This is done in-place to avoid creating a copy of the matrix.

  % Identify positions where a connection can be added.
  add_connection_mask = rand(pn, 2 * tn) <= prob;
  mask_to_apply = (cm(:, 1:2*tn) == 0) & add_connection_mask;

  % Create a full-sized logical mask to use for direct assignment.
  full_mask = false(size(cm));
  full_mask(:, 1:2*tn) = mask_to_apply;
  % Add the new connections directly to the compound matrix.
  cm(full_mask) = 1;

  % --- Set the initial marking (M0) ---
  % If the initial marking is all zeros, create a random marking to ensure
  % the SPN can evolve.
  if all(cm(:, end) == 0)
    cm(:, end) = rand(pn, 1) > 0.5;
  endif

  % --- Assign firing rates (lambda) ---
  lambda = randi(max_lambda, tn, 1);
endfunction