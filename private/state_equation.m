%% [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
%%
%% Constructs the state-space equation matrix for a Continuous-Time Markov Chain (CTMC).
%%
%% This function builds the linear system `Q * pi = y`, which is used to solve
%% for the steady-state probability distribution (`pi`) of the markings in an SPN.
%% The matrix `Q` (here, `state_matrix`) is derived from the reachability graph
%% and the transition firing rates (`lambda`).
%%
%% The equation is formulated based on the principle that, at steady state, the
%% total probability flow into any state is equal to the total probability flow
%% out of that state.
%%
%% Inputs:
%%   v_list: A matrix of all reachable markings (states), where each column is
%%           a unique marking.
%%   edge_list: An m x 2 matrix listing the graph edges, where each row is a
%%              [source_idx, dest_idx] pair.
%%   arctrans_list: A vector where each element corresponds to an edge and
%%                  indicates which transition fired.
%%   lambda: A column vector of firing rates for each transition in the SPN.
%%
%% Outputs:
%%   state_matrix: The coefficient matrix `Q` of the linear system. It is a
%%                 square matrix of size `num_markings` x `num_markings`.
%%   y_list: The constant vector `y` of the linear system. It is typically a
%%           vector of zeros, with a single '1' to enforce the constraint that
%%           all probabilities must sum to 1.

function [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
  num_markings = columns(v_list);

  % Initialize the state matrix Q with zeros.
  state_matrix = zeros(num_markings, num_markings);

  % The diagonal elements of Q represent the total rate of leaving a state.
  for i = 1:num_markings
    % Find all edges originating from the current marking (state i).
    source_edges = find(edge_list(:, 1) == i);
    % Get the transitions corresponding to these edges.
    leaving_transitions = arctrans_list(source_edges);
    % Sum the firing rates of these transitions.
    state_matrix(i, i) = -sum(lambda(leaving_transitions));
  endfor

  % The off-diagonal elements Q(i, j) represent the rate of moving from state j to state i.
  for i = 1:rows(edge_list)
    source_idx = edge_list(i, 1);
    dest_idx = edge_list(i, 2);
    transition_idx = arctrans_list(i);

    % Add the firing rate to the corresponding entry in the state matrix.
    state_matrix(dest_idx, source_idx) = state_matrix(dest_idx, source_idx) + lambda(transition_idx);
  endfor

  % To solve the system, we enforce the constraint that the sum of all
  % probabilities must equal 1. We do this by replacing the first equation
  % with `sum(pi) = 1`.
  state_matrix(1, :) = 1;

  % Create the constant vector `y`.
  y_list = zeros(num_markings, 1);
  y_list(1) = 1;
endfunction