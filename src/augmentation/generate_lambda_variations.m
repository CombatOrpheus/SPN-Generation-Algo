function [variations, lambda_values_list] = generate_lambda_variations(pn, rg, num_variations, min_firing_rate, max_firing_rate)
  % GENERATE_LAMBDA_VARIATIONS Generates variations by altering transition firing rates.
  %
  % Inputs:
  %   pn                 - Petri net struct
  %   rg                 - Reachability graph struct
  %   num_variations     - Number of variations to generate
  %   min_firing_rate    - Minimum firing rate
  %   max_firing_rate    - Maximum firing rate
  %
  % Outputs:
  %   variations         - Cell array of variation structs
  %   lambda_values_list - Cell array of lambda vectors

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
