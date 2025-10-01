%% [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
%%
%% Constructs the state-space equation matrix for a Continuous-Time Markov Chain (CTMC).
%%
%% This function builds the linear system `Q * pi = y`, which is used to solve
%% for the steady-state probability distribution (`pi`) of the markings in an SPN.
%% The matrix `Q` (here, `state_matrix`) is derived from the reachability graph
%% and the transition firing rates (`lambda`).
%%
%% This version constructs the matrix in a sparse format to efficiently handle
%% large state spaces.
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
%%   state_matrix: The sparse coefficient matrix `Q` of the linear system. It is a
%%                 square matrix of size `num_markings` x `num_markings`.
%%   y_list: The constant vector `y` of the linear system. It is typically a
%%           vector of zeros, with a single '1' to enforce the constraint that
%%           all probabilities must sum to 1.

function [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
  num_markings = columns(v_list);

  % --- 1. Off-diagonal elements ---
  % These represent the rate of moving from a source state (j) to a dest state (i).
  % The entry is Q(i, j) = lambda_k for a transition k from j to i.
  source_indices = edge_list(:, 1);
  dest_indices = edge_list(:, 2);
  transition_indices = arctrans_list(:);
  off_diag_vals = lambda(transition_indices);

  % --- 2. Diagonal elements ---
  % These represent the total rate of leaving a state (j).
  % The entry is Q(j, j) = -sum(lambdas of outgoing transitions from j).
  % We use accumarray to efficiently sum the lambdas for each source state.
  diag_sums = accumarray(source_indices, off_diag_vals, [num_markings 1], @sum, 0);
  diag_indices = (1:num_markings)';
  diag_vals = -diag_sums;

  % --- 3. Combine all triplets for sparse matrix construction ---
  all_rows = [dest_indices; diag_indices];
  all_cols = [source_indices; diag_indices];
  all_vals = [off_diag_vals; diag_vals];

  % --- 4. Construct the sparse matrix ---
  % The sparse() function automatically sums values for duplicate (row, col) pairs,
  % which correctly handles multiple transitions between the same two states.
  state_matrix = sparse(all_rows, all_cols, all_vals, num_markings, num_markings);

  % --- 5. Enforce probability constraint ---
  % To solve the system, we replace the first equation with `sum(pi) = 1`.
  % This makes the matrix non-singular.
  state_matrix(1, :) = 1;

  % --- 6. Create the constant vector `y` ---
  y_list = zeros(num_markings, 1);
  y_list(1) = 1;
endfunction