## -*- texinfo -*-
## @deftypefn {} {@var{stats} =} calculate_stats (@var{results})
## Compute aggregated statistics across generated SPN samples.
##
## Summarizes metrics including total sample count, average place count, average
## transition count, average token count across places, and average steady-state probability.
##
## @table @asis
## @item @var{results}
## Cell array of sample structs containing @code{num_places}, @code{num_transitions},
## and optionally @code{average_markings} and @code{steady_state_probs}.
## @end table
##
## Returns struct @var{stats} containing the computed averages.
##
## @seealso{generate_parallel_dataset, generate_html_report}
## @end deftypefn
function stats = calculate_stats(results)

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

