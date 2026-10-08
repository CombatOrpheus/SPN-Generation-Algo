## -*- texinfo -*-
## @deftypefn {} {[@var{probs}, @var{err}] =} solve_steady_state_iterative (@var{rg}, @var{lambda_values})
## @deftypefnx {} {[@var{probs}, @var{err}] =} solve_steady_state_iterative (@var{rg}, @var{lambda_values}, @var{max_iter}, @var{tol})
## @deftypefnx {} {[@var{probs}, @var{err}] =} solve_steady_state_iterative (@var{rg}, @var{lambda_values}, @var{max_iter}, @var{tol}, @var{force_pure_octave})
## Solve for steady-state distribution using sparse uniformization power iteration.
##
## Computes the stationary probability vector @math{\pi} of the Continuous-Time
## Markov Chain (CTMC) through uniformization into a discrete-time Markov chain.
## Uses high-performance C++ extension (@file{solve_steady_state_oct}) when compiled,
## with an optimized pure Octave fallback.
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
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, bypasses compiled oct-file.
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
function [probs, err] = solve_steady_state_iterative(rg, lambda_values, max_iter, tol, force_pure_octave)

  if nargin < 3 || isempty(max_iter)
    max_iter = 50000;
  endif
  if nargin < 4 || isempty(tol)
    tol = 1e-10;
  endif
  if nargin < 5 || isempty(force_pure_octave)
    force_pure_octave = false;
  endif

  V = int32(rg.num_vertices);
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
    probs = ones(V, 1) / double(V);
    err = false;
    return;
  endif

  if !force_pure_octave && exist("solve_steady_state_oct", "file") == 3
    try
      [probs, err] = solve_steady_state_oct(int32(rg.edges), int32(rg.arc_transitions), double(lambda_values), V, int32(max_iter), double(tol));
      return;
    catch
      % Fallback to pure Octave if dynamic link or execution fails
    end_try_catch
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

  % Form transposed sparse uniformized matrix PT directly in column-major CSC format.
  % Transition from src to dest: P(src, dest) = rates / gamma -> PT(dest, src) = rates / gamma
  % Operating as pi^(k+1) = PT * pi^k on column vectors avoids transpositions and improves cache locality.
  diag_vals = 1.0 - (q / gamma);

  rows_t = [dest_ns; (1:V)'];
  cols_t = [src_ns; (1:V)'];
  vals_t = [rates_ns / gamma; diag_vals];

  PT = sparse(rows_t, cols_t, vals_t, V, V);

  % Uniform initialization: column vector
  pi_col = ones(V, 1) / double(V);
  err = true;

  % Batched power iteration with periodic L1 convergence checking and normalization
  batch_size = 15;
  for iter = 1:batch_size:max_iter
    pi_prev = pi_col;
    num_steps = min(batch_size, max_iter - iter + 1);
    for b = 1:num_steps
      pi_col = PT * pi_col;
    endfor

    s = sum(pi_col);
    if s > 0
      pi_col = pi_col / s;
    endif

    if sum(abs(pi_col - pi_prev)) < tol
      err = false;
      break;
    endif
  endfor

  probs = pi_col;
  probs(probs < 0) = 0.0;
  prob_sum = sum(probs);
  if prob_sum > 1e-9
    probs = probs / prob_sum;
  else
    err = true;
  endif
endfunction
