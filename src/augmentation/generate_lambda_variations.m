## -*- texinfo -*-
## @deftypefn {} {[@var{variations}, @var{lambda_values_list}] =} generate_lambda_variations (@var{pn}, @var{rg}, @var{num_variations}, @var{min_firing_rate}, @var{max_firing_rate})
## Generate variations by altering transition firing rates.
##
## Computes alternative steady-state solutions on the fixed reachability graph @var{rg}
## under perturbed transition firing rate vectors $\lambda$.
##
## @table @asis
## @item @var{pn}
## Petri net struct.
##
## @item @var{rg}
## Reachability graph struct.
##
## @item @var{num_variations}
## Integer target number of variations.
##
## @item @var{min_firing_rate}
## Lower bound for randomly generated firing rates.
##
## @item @var{max_firing_rate}
## Upper bound for randomly generated firing rates.
## @end table
##
## Outputs:
## @table @asis
## @item @var{variations}
## Cell array of variation structs containing updated steady-state solutions and average markings.
##
## @item @var{lambda_values_list}
## Cell array of generated transition firing rate vectors.
## @end table
##
## @seealso{generate_petrinet_variations, solve_steady_state}
## @end deftypefn
function [variations, lambda_values_list] = generate_lambda_variations(pn, rg, num_variations, min_firing_rate, max_firing_rate)

  % Pre-allocate output cell arrays
  variations = cell(num_variations, 1);
  lambda_values_list = cell(num_variations, 1);
  var_count = 0;

  T = pn.transitions;

  for i = 1:num_variations
    lambda_values = double(randi([min_firing_rate, max_firing_rate], T, 1));

    [probs, err] = solve_steady_state(rg, lambda_values);
    if err
      continue;
    endif

    [avg_m, densities] = compute_average_markings(rg, probs);

    v = struct();
    v.steady_state_probs = probs;
    v.average_markings = avg_m;
    v.marking_densities = densities;

    var_count = var_count + 1;
    variations{var_count} = v;
    lambda_values_list{var_count} = lambda_values;
  endfor

  % Truncate to actual generated count
  variations = variations(1:var_count);
  lambda_values_list = lambda_values_list(1:var_count);
endfunction
