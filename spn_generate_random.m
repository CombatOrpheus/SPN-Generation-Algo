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
  % Initialize the compound matrix with zeros. Using "int32" for memory efficiency.
  cm = zeros(pn, 2*tn + 1, "int32");

  % Create unique identifiers for places and transitions.
  % Places are identified by integers 1 to pn.
  % Transitions are identified by integers (pn + 1) to (pn + tn).
  places = [1:pn]';
  transitions = [1:tn]' + pn;
  all_nodes = [places; transitions];

  % --- Start building a connected graph ---
  % This part of the algorithm ensures that all places and transitions are
  % connected, forming a single component graph.

  % Maintain separate dynamically growing arrays for places and transitions
  % to avoid O(N^2) complexity from logical filtering inside the loop.
  places_in_subgraph = zeros(pn, 1);
  transitions_in_subgraph = zeros(tn, 1);
  places_count = 0;
  transitions_count = 0;
  % A list of nodes yet to be added to the subgraph.
  remaining_nodes = all_nodes;

  % 1. Start with a random place and a random transition.
  start_place = randi(pn);
  start_transition = randi(tn) + pn;

  % Add them to our subgraph.
  places_count++;
  places_in_subgraph(places_count) = start_place;
  transitions_count++;
  transitions_in_subgraph(transitions_count) = start_transition;

  % Remove them from the list of remaining nodes.
  remaining_nodes(remaining_nodes == start_place) = [];
  remaining_nodes(remaining_nodes == start_transition) = [];

  % Create a connection between the starting place and transition.
  % The direction is chosen randomly.
  % Note: transition indices in the matrix are from 1 to tn.
  transition_idx = start_transition - pn;
  if rand() <= 0.5
    % Connect place to transition (place is an input to the transition).
    cm(start_place, transition_idx) = 1;
  else
    % Connect transition to place (place is an output of the transition).
    cm(start_place, tn + transition_idx) = 1;
  endif

  % 2. Iteratively add the remaining nodes to the subgraph.
  % We shuffle the remaining nodes to add them in a random order.
  shuffled_nodes = remaining_nodes(randperm(numel(remaining_nodes)));
  num_nodes = length(shuffled_nodes);

  % Pre-calculate random choices to avoid randi() and rand() overhead inside the loop
  rand_choices_t = randi(intmax('int32'), num_nodes, 1);
  rand_choices_p = randi(intmax('int32'), num_nodes, 1);
  rand_dir = rand(num_nodes, 1) > 0.5;

  for k = 1:num_nodes
    node = shuffled_nodes(k);
    if node <= pn % The current node to add is a place.
      % Connect this new place to a random transition already in the subgraph.
      new_place = node;
      connected_transition = transitions_in_subgraph(mod(rand_choices_t(k), transitions_count) + 1);
      places_count++;
      places_in_subgraph(places_count) = node;
    else % The current node to add is a transition.
      % Connect this new transition to a random place already in the subgraph.
      new_place = places_in_subgraph(mod(rand_choices_p(k), places_count) + 1);
      connected_transition = node;
      transitions_count++;
      transitions_in_subgraph(transitions_count) = node;
    endif

    % Create a connection between the new node and a node from the subgraph.
    transition_idx = connected_transition - pn;
    cm(new_place, transition_idx + rand_dir(k) * tn) = 1;
  endfor

  % --- Add more connections based on probability ---
  % At this point, we have a connected graph. Now, we can add more edges
  % to increase the complexity of the Petri net.

  % For each potential connection that doesn't exist yet, we add it with
  % a probability `prob`.
  % We generate a matrix of random numbers and find where they are less than `prob`.
  add_connection_mask = rand(pn, 2*tn) <= prob;

  % Get the part of the matrix for connections (excluding M0).
  connections_matrix = cm(:, 1:end-1);

  % Find elements that are currently 0 and are selected by the random mask.
  mask_to_apply = (connections_matrix == 0) & add_connection_mask;

  % Set those elements to 1.
  connections_matrix(mask_to_apply) = 1;

  % Put the modified part back into the main compound matrix.
  cm(:, 1:end-1) = connections_matrix;

  % --- Set the initial marking (M0) ---
  % If the initial marking column is all zeros, create a random marking.
  % This ensures the SPN can evolve from its initial state.
  if (all(cm(:, end) == 0))
    % Each place has a 50% chance of having one token.
    cm(:, end) = randi(2, pn, 1) - 1;
  endif

  % --- Assign firing rates (lambda) to transitions ---
  % For each transition, choose a random integer value from 1 to max_lambda.
  lambda = randi(max_lambda, tn, 1);
endfunction