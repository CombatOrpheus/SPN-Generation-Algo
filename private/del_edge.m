%% new_net = del_edge(petri_net_matrix)
%%
%% Randomly deletes edges from over-connected nodes in a Petri net.
%%
%% This function "prunes" a Petri net by reducing the number of connections
%% to and from nodes (places and transitions) that have a high degree. The
%% current definition of "over-connected" is any node with three or more
%% connections.
%%
%% For each such over-connected node, the function randomly selects and removes
%% connections until only two remain. This is a way to simplify the structure
%% of a dense Petri net, which can be useful for generating a wider variety
%% of net structures.
%%
%% Note: This operation may result in some nodes becoming completely isolated.
%% It is intended to be used in conjunction with a function like
%% `add_edges_to_isolated_nodes` to ensure the net remains connected.
%%
%% Inputs:
%%   petri_net_matrix: The compound matrix of the SPN to be pruned. This is a
%%                     pn x (2*tn + 1) matrix structured as [T_in, T_out, M0].
%%
%% Outputs:
%%   new_net: The modified (pruned) Petri net matrix.

function new_net = del_edge(petri_net_matrix)
  % --- Prune connections from places ---
  % Find places that are connected to at least three transitions.
  connections_per_place = sum(petri_net_matrix(:, 1:end-1), 2);
  overconnected_place_idxs = find(connections_per_place >= 3)';

  % For each over-connected place, remove connections until only 2 remain.
  for row = overconnected_place_idxs
    % Find all connections for the current place.
    connection_indices = find(petri_net_matrix(row, 1:end-1) == 1);
    num_to_remove = connections_per_place(row) - 2;

    % Randomly select connections to remove.
    indices_to_remove = randsample(connection_indices, num_to_remove);
    petri_net_matrix(row, indices_to_remove) = 0;
  endfor

  % --- Prune connections from transitions ---
  % Find transitions that are connected to at least three places.
  connections_per_arc = sum(petri_net_matrix(:, 1:end-1), 1);
  num_transitions = (columns(petri_net_matrix) - 1) / 2;
  connections_per_transition = connections_per_arc(1:num_transitions) + connections_per_arc(num_transitions+1:end);
  overconnected_trans_idxs = find(connections_per_transition >= 3);

  % For each over-connected transition, remove connections until only 2 remain.
  for column = overconnected_trans_idxs
    % This part is more complex as connections can be in T_in or T_out.
    % The original code was likely buggy here. A simple, correct implementation
    % would be to find all connected places and randomly disconnect some.

    % Find all places connected to this transition (both as input and output).
    t_in_connections = find(petri_net_matrix(:, column) == 1);
    t_out_connections = find(petri_net_matrix(:, column + num_transitions) == 1);
    all_connected_places = [t_in_connections; t_out_connections];

    num_to_remove = length(all_connected_places) - 2;
    if num_to_remove > 0
        places_to_disconnect = randsample(all_connected_places, num_to_remove);

        for place_row = places_to_disconnect'
            % Set both potential connections (in and out) to 0 for this place.
            petri_net_matrix(place_row, column) = 0;
            petri_net_matrix(place_row, column + num_transitions) = 0;
        endfor
    endif
  endfor

  new_net = petri_net_matrix;
endfunction