## -*- texinfo -*-
## @deftypefn {} {[@var{state_matrix}, @var{target_vector}] =} compute_state_equation (@var{rg}, @var{lambda_values})
## Compute infinitesimal generator state equation for the SPN.
##
## Constructs the augmented transpose generator matrix @math{Q^T} and target vector
## enforcing the steady-state equation @math{\pi Q = 0} alongside the normalization
## constraint @math{\sum \pi_i = 1}.
##
## @table @asis
## @item @var{rg}
## Reachability graph struct (@code{vertices}, @code{edges}, @code{arc_transitions}).
##
## @item @var{lambda_values}
## Vector of transition firing rates.
## @end table
##
## Outputs:
## @table @asis
## @item @var{state_matrix}
## Sparse @math{(V+1) \times V} matrix representing @math{Q^T} with probability sum constraint row.
##
## @item @var{target_vector}
## Column vector of length @math{V+1} with zeros and 1.0 at index @math{V+1}.
## @end table
##
## @seealso{solve_steady_state, solve_steady_state_iterative}
## @end deftypefn
function [state_matrix, target_vector] = compute_state_equation(rg, lambda_values)

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

