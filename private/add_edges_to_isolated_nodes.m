%% new_net = add_edges_to_isolated_nodes(petri_net_matrix)
%%
%% Ensures that every place and transition in a Petri net has at least one connection.
%%
%% This function inspects the Petri net for any places or transitions that
%% have become disconnected (isolated) and adds random edges to reconnect them.
%%
%% NOTE: This function was originally named `add_node`, which was misleading.
%%
%% Inputs:
%%   petri_net_matrix: The compound matrix of the SPN.
%%
%% Outputs:
%%   new_net: The modified petri net matrix with no isolated nodes.

function new_net = add_edges_to_isolated_nodes(petri_net_matrix)
  num_places = rows(petri_net_matrix);
  num_transitions = (columns(petri_net_matrix) - 1) / 2;

  % --- Reconnect isolated places ---
  % Find any rows (places) that have no connections.
  isolated_rows = find(all(petri_net_matrix(:, 1:end-1) == 0, 2))';
  for row = isolated_rows
    % Add a random incoming and outgoing arc to reconnect the place.
    in_transition = randi(num_transitions);
    out_transition = randi(num_transitions);
    petri_net_matrix(row, in_transition) = 1;
    petri_net_matrix(row, num_transitions + out_transition) = 1;
  endfor

  % --- Reconnect isolated transitions ---
  % Find any transitions that have no connections.
  connections_per_arc = sum(petri_net_matrix(:, 1:end-1), 1);
  connections_per_transition = connections_per_arc(1:num_transitions) + connections_per_arc(num_transitions+1:end);
  isolated_transitions = find(connections_per_transition == 0);

  for trans_idx = isolated_transitions
    % Add a connection to a random place.
    random_place = randi(num_places);
    % Randomly decide if it's an incoming or outgoing arc.
    if rand() > 0.5
        petri_net_matrix(random_place, trans_idx) = 1; % Place -> Transition
    else
        petri_net_matrix(random_place, trans_idx + num_transitions) = 1; % Transition -> Place
    endif
  endfor

  new_net = petri_net_matrix;
endfunction
