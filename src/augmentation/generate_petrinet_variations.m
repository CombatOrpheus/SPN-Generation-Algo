function variations = generate_petrinet_variations(pn, place_upper_bound, marks_lower_limit, marks_upper_limit, num_variations, min_firing_rate, max_firing_rate)
  % GENERATE_PETRINET_VARIATIONS Generates variations of a Petri net by adding/removing tokens.
  %
  % Inputs:
  %   pn                - Base Petri net struct
  %   place_upper_bound - Maximum tokens allowed per place
  %   marks_lower_limit - Minimum required markings in reachability graph
  %   marks_upper_limit - Maximum allowable markings in reachability graph
  %   num_variations    - Number of variations to attempt to generate
  %   min_firing_rate   - Minimum firing rate
  %   max_firing_rate   - Maximum firing rate
  %
  % Outputs:
  %   variations - Cell array of variation structs

  % Pre-allocate variations cell array
  variations = cell(num_variations, 1);
  var_count = 0;

  P = pn.places;
  T = pn.transitions;
  m0_col = 2 * T + 1;

  for i = 1:num_variations
    var_pn = pn;

    changed = false;
    if rand() < 0.5
      % Add tokens
      p = randi(P);
      if var_pn.initial_marking(p) < place_upper_bound
        var_pn.initial_marking(p) = var_pn.initial_marking(p) + 1;
        var_pn.matrix(p, m0_col) = var_pn.matrix(p, m0_col) + 1;
        changed = true;
      endif
    else
      % Remove tokens
      p = randi(P);
      if var_pn.initial_marking(p) > 0
        var_pn.initial_marking(p) = var_pn.initial_marking(p) - 1;
        var_pn.matrix(p, m0_col) = var_pn.matrix(p, m0_col) - 1;
        changed = true;
      endif
    endif

    if !changed
      continue;
    endif

    rg = generate_reachability_graph(var_pn, place_upper_bound, marks_upper_limit);
    if !rg.is_bounded || rg.num_vertices < marks_lower_limit
      continue;
    endif

    % Random firing rates
    lambda_values = double(randi([min_firing_rate, max_firing_rate], T, 1));

    [probs, err] = solve_steady_state(rg, lambda_values);
    if err
      continue;
    endif

    [avg_m, densities] = compute_average_markings(rg, probs);

    v = struct();
    v.petri_net = var_pn;
    v.reachability_graph = rg;
    v.lambda_values = lambda_values;
    v.steady_state_probs = probs;
    v.average_markings = avg_m;
    v.marking_densities = densities;

    var_count = var_count + 1;
    variations{var_count} = v;
  endfor

  % Truncate to actual generated count
  variations = variations(1:var_count);
endfunction
