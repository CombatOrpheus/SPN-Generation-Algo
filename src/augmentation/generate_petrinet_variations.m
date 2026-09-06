## -*- texinfo -*-
## @deftypefn {} {@var{variations} =} generate_petrinet_variations (@var{pn}, @var{place_upper_bound}, @var{marks_lower_limit}, @var{marks_upper_limit}, @var{num_variations}, @var{min_firing_rate}, @var{max_firing_rate})
## Generate topological variations of a Petri net by adding or removing tokens.
##
## Perturbs the initial marking of @var{pn} by adding or decrementing tokens,
## recomputing reachability graphs and accepting variants whose state-space size
## falls strictly within [@var{marks_lower_limit}, @var{marks_upper_limit}].
##
## @table @asis
## @item @var{pn}
## Base Petri net struct.
##
## @item @var{place_upper_bound}
## Maximum token capacity per place during reachability exploration.
##
## @item @var{marks_lower_limit}
## Minimum required markings in reachability graph.
##
## @item @var{marks_upper_limit}
## Maximum allowable markings in reachability graph.
##
## @item @var{num_variations}
## Target number of variations to attempt.
##
## @item @var{min_firing_rate}
## Minimum transition firing rate for CTMC solving.
##
## @item @var{max_firing_rate}
## Maximum transition firing rate for CTMC solving.
## @end table
##
## Returns cell array of variation structs.
##
## @seealso{generate_lambda_variations, generate_reachability_graph}
## @end deftypefn
function variations = generate_petrinet_variations(pn, place_upper_bound, marks_lower_limit, marks_upper_limit, num_variations, min_firing_rate, max_firing_rate)

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
