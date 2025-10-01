%% bool = has_no_isolated_nodes(petri_matrix)
%%
%% Checks if a Petri net has any isolated (disconnected) nodes.
%%
%% An isolated node is a place or a transition that has no connections to any
%% other node in the net (i.e., its total in-degree and out-degree is zero).
%%
%% This function provides a basic check for connectivity. It is a necessary,
%% but not sufficient, condition for a Petri net graph to be strongly connected.
%% It is used as an initial, fast filter to discard obviously invalid nets.
%%
%% Inputs:
%%   petri_matrix: The compound matrix of the SPN. This is a pn x (2*tn + 1)
%%                 matrix structured as [T_in, T_out, M0]. The initial marking
%%                 (last column) is ignored for this check.
%%
%% Outputs:
%%   bool: A boolean value. Returns `true` if there are no isolated nodes in
%%         the Petri net, and `false` otherwise.

function bool = has_no_isolated_nodes(petri_matrix)
  % Exclude the last column (initial marking M0) from the analysis.
  incidence_matrix = petri_matrix(:, 1:end-1);
  num_transitions = columns(incidence_matrix) / 2;

  % Check for isolated places: the sum of all connections for each place (row) must be non-zero.
  if any(sum(incidence_matrix, 2) == 0)
    bool = false;
    return;
  endif

  % Check for isolated transitions: the sum of all connections for each transition must be non-zero.
  connection_sum_per_arc = sum(incidence_matrix, 1);
  % Sum the inflows (T_in) and outflows (T_out) for each transition.
  connections_per_transition = connection_sum_per_arc(1:num_transitions) + connection_sum_per_arc(num_transitions+1:end);
  if any(connections_per_transition == 0)
    bool = false;
    return;
  endif

  bool = true;
endfunction