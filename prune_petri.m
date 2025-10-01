%% new_net = prune_petri(petri_net_matrix)
%%
%% Randomly prunes and reconnects a Petri net to simplify its structure.
%%
%% This function serves as a structural modifier for a given Petri net. It
%% performs two main operations in sequence:
%% 1. Edge Deletion (`del_edge`): It identifies nodes (both places and
%%    transitions) that are "over-connected" (currently defined as having
%%    three or more connections) and randomly removes some of these connections
%%    to reduce their degree.
%% 2. Edge Addition (`add_edges_to_isolated_nodes`): After pruning, some nodes
%%    may have become completely disconnected from the net. This step identifies
%%    any such isolated nodes and adds new, random connections to reintegrate
%%    them into the graph, ensuring the net remains whole.
%%
%% This function is useful for transforming a dense or complex Petri net into a
%% sparser version while preserving its basic components.
%%
%% Inputs:
%%   petri_net_matrix: The compound matrix of the SPN to be pruned. This is a
%%                     pn x (2*tn + 1) matrix structured as [T_in, T_out, M0].
%%
%% Outputs:
%%   new_net: A new compound matrix of the same dimensions, representing the
%%            modified (pruned and reconnected) Petri net.

function new_net = prune_petri(petri_net_matrix)
  % First, delete edges from nodes that are too connected.
  temp_net = del_edge(petri_net_matrix);

  % Then, add edges back to any nodes that may have become isolated.
  new_net = add_edges_to_isolated_nodes(temp_net);
endfunction