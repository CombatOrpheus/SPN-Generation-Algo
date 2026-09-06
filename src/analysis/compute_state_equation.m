function [state_matrix, target_vector] = compute_state_equation(rg, lambda_values)
  % COMPUTE_STATE_EQUATION Computes infinitesimal generator state equation for the SPN.
  %
  % Inputs:
  %   rg            - Reachability graph struct (vertices, edges, arc_transitions)
  %   lambda_values - Vector of firing rates for transitions (1-based indices)
  %
  % Outputs:
  %   state_matrix  - (V+1) x V matrix representing Q^T with probability sum row
  %   target_vector - (V+1) x 1 vector with 1 at the last entry

  V = rg.num_vertices;
  target_vector = zeros(V + 1, 1);
  target_vector(V + 1) = 1.0;

  if rg.num_edges > 0
    src_idx = double(rg.edges(:, 1));
    dest_idx = double(rg.edges(:, 2));
    rates = lambda_values(double(rg.arc_transitions(:)));

    % Q^T has rates at (dest, src) and -rates at (src, src).
    % The probability sum constraint row at V+1 has 1.0 for each column (1:V).
    rows = [dest_idx; src_idx; repmat(V + 1, V, 1)];
    cols = [src_idx; src_idx; (1:V)'];
    vals = [rates; -rates; ones(V, 1)];
  else
    rows = repmat(V + 1, V, 1);
    cols = (1:V)';
    vals = ones(V, 1);
  endif

  if V > 50
    state_matrix = sparse(rows, cols, vals, V + 1, V);
  else
    state_matrix = full(sparse(rows, cols, vals, V + 1, V));
  endif
endfunction

