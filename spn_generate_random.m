%% [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda, num_matrices, use_shared_structure)
%%
%% Generates one or more random, connected Stochastic Petri Nets (SPNs).
%%
%% This function generates SPNs by first ensuring a connected graph of places
%% and transitions, then adding random connections and properties. It can
%% generate multiple matrices at once.
%%
%% The function can operate in two modes:
%% 1. Independent Mode (default): Generates `num_matrices` completely
%%    independent SPNs.
%% 2. Shared Structure Mode: Generates a single base connected graph and
%%    replicates it `num_matrices` times. Each of these copies then gets its
%%    own set of additional random connections, markings, and firing rates.
%%
%% Note: This function does not guarantee properties like liveness or
%% boundedness; these should be verified by a separate filter function.
%%
%% Inputs:
%%   pn: An integer specifying the number of places in the net.
%%   tn: An integer specifying the number of transitions in the net.
%%   prob: A probability (scalar from 0 to 1) of adding an extra random
%%         connection.
%%   max_lambda: An integer specifying the maximum value for firing rates.
%%   num_matrices (optional): The number of SPNs to generate. Default is 1.
%%   use_shared_structure (optional): A boolean flag for shared structure mode.
%%                                    Default is false.
%%
%% Outputs:
%%   cm: The compound matrix (or matrices) of the generated SPN(s).
%%       If `num_matrices` > 1, this is a `pn x (2*tn + 1) x num_matrices` 3D matrix.
%%       If `num_matrices` is 1, this is a 2D matrix.
%%
%%   lambda: The firing rates. If `num_matrices` > 1, this is a `tn x num_matrices` matrix.
%%           If `num_matrices` is 1, this is a `tn x 1` vector.

function [cm_out, lambda_out] = spn_generate_random(pn, tn, prob, max_lambda, num_matrices = 1, use_shared_structure = false)
  % Pre-allocate output matrices
  cm_out = zeros(pn, 2*tn + 1, num_matrices, "int32");
  lambda_out = zeros(tn, num_matrices, "int32");

  base_cm = [];

  if use_shared_structure
    % Generate the base connected graph once
    base_cm = _generate_connected_graph(pn, tn);
  endif

  % Loop to generate each matrix
  for k = 1:num_matrices
    if use_shared_structure
      % Start with the pre-generated base graph
      cm = base_cm;
    else
      % Generate a new connected graph for each matrix
      cm = _generate_connected_graph(pn, tn);
    endif

    % --- Add more connections based on probability ---
    add_connection_mask = rand(pn, 2*tn) <= prob;
    connections_matrix = cm(:, 1:2*tn);
    mask_to_apply = (connections_matrix == 0) & add_connection_mask;
    connections_matrix(mask_to_apply) = 1;
    cm(:, 1:2*tn) = connections_matrix;

    % --- Set the initial marking (M0) ---
    if (all(cm(:, end) == 0))
      cm(:, end) = randi(2, pn, 1) - 1;
    endif

    % --- Assign firing rates (lambda) ---
    lambda = randi(max_lambda, tn, 1);

    % Store the results
    cm_out(:, :, k) = cm;
    lambda_out(:, k) = lambda;
  endfor

  % Squeeze output for backward compatibility if only one matrix was generated
  if num_matrices == 1
    cm_out = squeeze(cm_out);
  endif
endfunction

% --- Private helper to generate a single connected graph ---
function cm = _generate_connected_graph(pn, tn)
  cm = zeros(pn, 2*tn + 1, "int32");
  places = (1:pn)';
  transitions = (1:tn)' + pn;
  all_nodes = [places; transitions];

  subgraph_nodes = [];
  remaining_nodes = all_nodes;

  % 1. Start with a random place and transition
  start_place = randi(pn);
  start_transition = randi(tn) + pn;
  subgraph_nodes = [start_place; start_transition];
  remaining_nodes(remaining_nodes == start_place) = [];
  remaining_nodes(remaining_nodes == start_transition) = [];

  transition_idx = start_transition - pn;
  if rand() <= 0.5
    cm(start_place, transition_idx) = 1;
  else
    cm(start_place, tn + transition_idx) = 1;
  endif

  % 2. Iteratively add remaining nodes
  shuffled_nodes = remaining_nodes(randperm(numel(remaining_nodes)));
  for node = shuffled_nodes'
    is_place_in_subgraph = subgraph_nodes <= pn;
    places_in_subgraph = subgraph_nodes(is_place_in_subgraph);
    transitions_in_subgraph = subgraph_nodes(~is_place_in_subgraph);

    if node <= pn % Node is a place
      new_place = node;
      connected_transition = random_choice(transitions_in_subgraph);
    else % Node is a transition
      new_place = random_choice(places_in_subgraph);
      connected_transition = node;
    endif

    subgraph_nodes = [subgraph_nodes; node];
    transition_idx = connected_transition - pn;
    if rand() <= 0.5
      cm(new_place, transition_idx) = 1;
    else
      cm(new_place, tn + transition_idx) = 1;
    endif
  endfor
endfunction