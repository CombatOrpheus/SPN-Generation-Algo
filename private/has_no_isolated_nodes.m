%% has_nodes = has_no_isolated_nodes(petri_matrix)
%%
%% Checks if a Petri net has any isolated places or transitions.
%%
%% An isolated place has no input or output arcs. An isolated transition
%% also has no input or output arcs. This is a necessary, but not sufficient,
%% condition for a graph to be strongly connected.
%%
%% Inputs:
%%   petri_matrix: The compound matrix of the SPN.
%%
%% Outputs:
%%   bool: Returns `true` if there are no isolated nodes, `false` otherwise.

function bool = has_no_isolated_nodes(petri_matrix)
  % Exclude the last column (initial marking M0) from the analysis.
  incidence_matrix = petri_matrix(:, 1:end-1);
  num_transitions = columns(incidence_matrix) / 2;

  % Check for isolated places: sum of all connections for each place must be non-zero.
  if any(sum(incidence_matrix, 2) == 0)
    bool = false;
    return;
  endif

  % Check for isolated transitions: sum of all connections for each transition must be non-zero.
  connection_sum_per_arc = sum(incidence_matrix, 1);
  % Sum the inflows and outflows for each transition.
  connections_per_transition = connection_sum_per_arc(1:num_transitions) + connection_sum_per_arc(num_transitions+1:end);
  if any(connections_per_transition == 0)
    bool = false;
    return;
  endif

  bool = true;
endfunction
