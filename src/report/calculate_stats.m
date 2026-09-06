function stats = calculate_stats(results)
  % CALCULATE_STATS Computes aggregated statistics across generated samples.
  %
  % Inputs:
  %   results - Cell array of structs with fields:
  %             num_places, num_transitions, average_markings, steady_state_probs
  %
  % Outputs:
  %   stats - Struct containing summary metrics

  stats = struct();
  n = length(results);
  stats.num_samples = n;

  if n == 0
    stats.avg_places = 0.0;
    stats.avg_transitions = 0.0;
    stats.avg_markings = 0.0;
    stats.avg_steady_state_probs = 0.0;
    return;
  endif

  % Convert cell array of scalar structs to struct array for fast vectorized field access
  s = [results{:}];

  stats.avg_places = mean([s.num_places]);
  stats.avg_transitions = mean([s.num_transitions]);

  if isfield(s, "average_markings")
    stats.avg_markings = mean(cellfun(@sum, {s.average_markings}));
  else
    stats.avg_markings = 0.0;
  endif

  if isfield(s, "steady_state_probs")
    stats.avg_steady_state_probs = mean(cellfun(@sum, {s.steady_state_probs}));
  else
    stats.avg_steady_state_probs = 0.0;
  endif
endfunction

