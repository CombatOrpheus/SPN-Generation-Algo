## -*- texinfo -*-
## @deftypefn {} {[@var{probs}, @var{err}] =} solve_steady_state_iterative (@var{rg}, @var{lambda_values})
## @deftypefnx {} {[@var{probs}, @var{err}] =} solve_steady_state_iterative (@var{rg}, @var{lambda_values}, @var{max_iter}, @var{tol})
## Solve for steady-state distribution using sparse uniformization power iteration.
##
## Computes the stationary probability vector @math{\pi} of the Continuous-Time
## Markov Chain (CTMC) through uniformization into a discrete-time Markov chain.
## Operates in @math{O(V)} memory and @math{O(|E|)} work per iteration, avoiding dense
## matrix allocations.
##
## @table @asis
## @item @var{rg}
## Reachability graph struct containing vertices, edges, and transitions.
##
## @item @var{lambda_values}
## Vector of firing rates for transitions.
##
## @item @var{max_iter}
## Optional maximum power iterations (default: 50000).
##
## @item @var{tol}
## Optional @math{L_1} convergence tolerance (default: 1e-10).
## @end table
##
## Outputs:
## @table @asis
## @item @var{probs}
## Column vector of length @math{V} with steady-state probabilities.
##
## @item @var{err}
## Boolean flag (true if power iteration failed to converge within @var{max_iter}).
## @end table
##
## @seealso{solve_steady_state, compute_state_equation}
## @end deftypefn
function [probs, err] = solve_steady_state_iterative(rg, lambda_values, max_iter, tol)

  if nargin < 3 || isempty(max_iter)
    max_iter = 50000;
  endif
  if nargin < 4 || isempty(tol)
    tol = 1e-10;
  endif

  V = rg.num_vertices;
  if V == 0
    probs = [];
    err = false;
    return;
  endif
  if V == 1
    probs = [1.0];
    err = false;
    return;
  endif

  if rg.num_edges == 0
    probs = ones(V, 1) / V;
    err = false;
    return;
  endif

  src = double(rg.edges(:, 1));
  dest = double(rg.edges(:, 2));
  rates = double(lambda_values(double(rg.arc_transitions(:))));

  % Exclude self-loops from exit rates
  non_self = (src ~= dest);
  src_ns = src(non_self);
  dest_ns = dest(non_self);
  rates_ns = rates(non_self);

  if isempty(src_ns)
    % All transitions are self-loops; all states absorbing
    probs = ones(V, 1) / V;
    err = false;
    return;
  endif

  % Calculate exit rates q_i per marking
  q = accumarray(src_ns, rates_ns, [V, 1]);
  max_q = max(q);

  if max_q == 0.0
    probs = ones(V, 1) / V;
    err = false;
    return;
  endif

  gamma = 1.01 * max_q;

  % Form sparse uniformized discrete-time transition probability matrix P
  % Off-diagonal: P(i, j) = q_ij / gamma
  % Diagonal: P(i, i) = 1 - q_i / gamma
  diag_vals = 1.0 - (q / gamma);

  rows = [src_ns; (1:V)'];
  cols = [dest_ns; (1:V)'];
  vals = [rates_ns / gamma; diag_vals];

  P_trans = sparse(rows, cols, vals, V, V);

  % Uniform initialization: row vector
  pi_vec = ones(1, V) / V;
  err = true;

  % Power iteration: pi^(k+1) = pi^k * P
  for iter = 1:max_iter
    pi_next = pi_vec * P_trans;

    % Normalize to prevent numerical drift
    s = sum(pi_next);
    if s > 0
      pi_next = pi_next / s;
    endif

    diff = sum(abs(pi_next - pi_vec));
    pi_vec = pi_next;

    if diff < tol
      err = false;
      break;
    endif
  endfor

  probs = pi_vec(:);
  probs(probs < 0) = 0.0;
  prob_sum = sum(probs);
  if prob_sum > 1e-9
    probs = probs / prob_sum;
  else
    err = true;
  endif
endfunction
