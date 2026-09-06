## -*- texinfo -*-
## @deftypefn  {} {[@var{probs}, @var{err}] =} solve_steady_state (@var{rg}, @var{lambda_values})
## @deftypefnx {} {[@var{probs}, @var{err}] =} solve_steady_state (@var{state_matrix}, @var{target_vector})
## Solve for steady-state probabilities of the continuous-time Markov chain.
##
## Polymorphic solver supporting:
## @enumerate
## @item @code{solve_steady_state(rg, lambda_values)}: Executes sparse iterative uniformization
## (power iteration) in $O(V)$ memory, falling back to direct LU decomposition if necessary.
## @item @code{solve_steady_state(state_matrix, target_vector)}: Solves the linear system
## directly via LU decomposition.
## @end enumerate
##
## Outputs:
## @table @asis
## @item @var{probs}
## Column vector of length @math{V} with the computed probability distribution.
##
## @item @var{err}
## Boolean flag indicating whether computation encountered a singularity or convergence error.
## @end table
##
## @seealso{solve_steady_state_iterative, compute_state_equation, compute_average_markings}
## @end deftypefn
function [probs, err] = solve_steady_state(arg1, arg2)

  if isstruct(arg1)
    % Called as solve_steady_state(rg, lambda_values)
    rg = arg1;
    lambda_values = arg2;

    [probs, err] = solve_steady_state_iterative(rg, lambda_values);
    if !err
      return;
    endif

    % Fallback to direct solve if iterative method fails to converge
    [state_matrix, target_vector] = compute_state_equation(rg, lambda_values);
  else
    % Called as solve_steady_state(state_matrix, target_vector)
    state_matrix = arg1;
    target_vector = arg2;
  endif

  V = size(state_matrix, 2);
  probs = zeros(V, 1);
  err = false;

  % Remove first equation to obtain square V x V system matching SPN-Algo-Go
  A = state_matrix(2:(V + 1), :);
  b = target_vector(2:(V + 1));

  % Locally disable singular matrix warnings during linear solve
  warning("off", "Octave:singular-matrix", "local");
  warning("off", "Octave:nearly-singular-matrix", "local");

  try
    if issparse(A)
      probs = full(A \ b);
    elseif V > 50
      probs = full(sparse(A) \ b);
    else
      probs = A \ b;
    endif
  catch e
    err = true;
    return;
  end_try_catch

  if any(isnan(probs)) || any(isinf(probs))
    err = true;
    return;
  endif

  % Ensure non-negative probabilities
  probs(probs < 0) = 0.0;
  prob_sum = sum(probs);

  if prob_sum > 1e-9
    probs = probs / prob_sum;
  else
    err = true;
    return;
  endif

  % Residual verification: check that steady-state balance equation holds
  residual = norm(A * probs - b, 1);
  if isnan(residual) || isinf(residual) || residual > 1e-3
    err = true;
  endif
endfunction
