%% new_net = prune_petri(petri_net_matrix)
%%
%% Randomly prunes and reconnects a Petri net.
%%
%% This function first removes edges from highly connected nodes (`del_edge`)
%% and then ensures there are no isolated nodes by adding connections back
%% where necessary (`add_edges_to_isolated_nodes`).
%%
%% Inputs:
%%   petri_net_matrix: The petri net compound matrix.
%%
%% Outputs:
%%   new_net: A modified Petri net matrix.

function new_net = prune_petri(petri_net_matrix)
  % First, delete edges from nodes that are too connected.
  temp_net = del_edge(petri_net_matrix);

  % Then, add edges back to any nodes that may have become isolated.
  new_net = add_edges_to_isolated_nodes(temp_net);
endfunction
