## -*- texinfo -*-
## @deftypefn {} {@var{stats} =} calculate_stats (@var{results})
## Compute comprehensive frequentist statistics across generated SPN samples.
##
## Summarizes metrics across the dataset including:
## @itemize @bullet
## @item Places (@math{P}) and Transitions (@math{T})
## @item Reachability Graph States (@math{S} / vertices) and State Transitions (@math{E} / edges)
## @item State-space branching density (@math{E/S})
## @item Total expected token population (@math{\sum E[M(p)]})
## @item Average tokens per place (@math{\frac{1}{P}\sum E[M(p)]})
## @item Maximum observed token count (@math{\max M(p)})
## @item Maximum steady-state state probability (@math{\max \pi_i})
## @item Steady-state probability conservation sum (@math{\sum \pi_i})
## @item Place starvation probability (@math{P(M(p) = 0)})
## @end itemize
##
## For each metric, calculates frequentist properties: sample count, mean,
## sample standard deviation, minimum, 25th percentile (Q1), median (Q2),
## 75th percentile (Q3), maximum, IQR, and histogram binning for graphical presentation.
##
## @table @asis
## @item @var{results}
## Cell array or struct array of sample structs.
## @end table
##
## Returns struct @var{stats} containing the computed statistics.
##
## @seealso{generate_parallel_dataset, generate_html_report, analyze_dataset, format_stats_table}
## @end deftypefn
function stats = calculate_stats(results)

  stats = struct();

  if isempty(results)
    n = 0;
  elseif iscell(results)
    n = length(results);
  elseif isstruct(results)
    n = length(results);
  else
    n = 0;
  endif

  stats.num_samples = n;

  if n == 0
    stats.avg_places = 0.0;
    stats.avg_transitions = 0.0;
    stats.avg_markings = 0.0;
    stats.avg_steady_state_probs = 0.0;

    stats.places = empty_metric_stats();
    stats.transitions = empty_metric_stats();
    stats.states = empty_metric_stats();
    stats.edges = empty_metric_stats();
    stats.density = empty_metric_stats();
    stats.total_tokens = empty_metric_stats();
    stats.tokens_per_place = empty_metric_stats();
    stats.max_tokens = empty_metric_stats();
    stats.max_prob = empty_metric_stats();
    stats.prob_sum = empty_metric_stats();
    stats.zero_token_prob = empty_metric_stats();
    stats.raw = struct();
    return;
  endif

  % Preallocate extraction vectors
  vec_places = zeros(n, 1);
  vec_transitions = zeros(n, 1);
  vec_states = zeros(n, 1);
  vec_edges = zeros(n, 1);
  vec_density = zeros(n, 1);
  vec_total_tokens = zeros(n, 1);
  vec_tokens_per_place = zeros(n, 1);
  vec_max_tokens = zeros(n, 1);
  vec_max_prob = zeros(n, 1);
  vec_prob_sum = zeros(n, 1);
  vec_zero_token_prob = zeros(n, 1);

  for i = 1:n
    if iscell(results)
      s = results{i};
    else
      s = results(i);
    endif

    [p, t, st, ed, am, probs, dens, mt] = extract_sample_fields(s);

    vec_places(i) = p;
    vec_transitions(i) = t;
    vec_states(i) = st;
    vec_edges(i) = ed;
    if st > 0
      vec_density(i) = double(ed) / double(st);
    else
      vec_density(i) = 0.0;
    endif

    % Average markings
    if !isempty(am)
      dam = double(am(:));
      tot_tok = sum(dam);
      vec_total_tokens(i) = tot_tok;
      if p > 0
        vec_tokens_per_place(i) = tot_tok / double(p);
      else
        vec_tokens_per_place(i) = mean(dam);
      endif
    else
      vec_total_tokens(i) = 0.0;
      vec_tokens_per_place(i) = 0.0;
    endif

    % Steady state probabilities
    if !isempty(probs)
      dprobs = double(probs(:));
      vec_max_prob(i) = max(dprobs);
      vec_prob_sum(i) = sum(dprobs);
    else
      vec_max_prob(i) = 0.0;
      vec_prob_sum(i) = 0.0;
    endif

    % Max tokens
    vec_max_tokens(i) = mt;

    % Zero-token probability (starvation)
    vec_zero_token_prob(i) = extract_zero_token_prob(dens, p);
  endfor

  % Compute frequentist statistics for each dimension
  stats.places = compute_metric_stats(vec_places);
  stats.transitions = compute_metric_stats(vec_transitions);
  stats.states = compute_metric_stats(vec_states);
  stats.edges = compute_metric_stats(vec_edges);
  stats.density = compute_metric_stats(vec_density);
  stats.total_tokens = compute_metric_stats(vec_total_tokens);
  stats.tokens_per_place = compute_metric_stats(vec_tokens_per_place);
  stats.max_tokens = compute_metric_stats(vec_max_tokens);
  stats.max_prob = compute_metric_stats(vec_max_prob);
  stats.prob_sum = compute_metric_stats(vec_prob_sum);
  stats.zero_token_prob = compute_metric_stats(vec_zero_token_prob);

  % Backward-compatible scalar summary fields
  stats.avg_places = stats.places.mean;
  stats.avg_transitions = stats.transitions.mean;
  stats.avg_markings = stats.total_tokens.mean;
  stats.avg_steady_state_probs = stats.prob_sum.mean;

  % Store raw arrays for presentation graph correlations
  stats.raw = struct();
  stats.raw.places = vec_places;
  stats.raw.transitions = vec_transitions;
  stats.raw.states = vec_states;
  stats.raw.edges = vec_edges;
  stats.raw.density = vec_density;
  stats.raw.total_tokens = vec_total_tokens;
  stats.raw.tokens_per_place = vec_tokens_per_place;
  stats.raw.max_tokens = vec_max_tokens;
  stats.raw.max_prob = vec_max_prob;
  stats.raw.prob_sum = vec_prob_sum;
  stats.raw.zero_token_prob = vec_zero_token_prob;
endfunction

function [p, t, st, ed, am, probs, dens, mt] = extract_sample_fields(s)
  % 1. Places
  if isfield(s, "num_places") && !isempty(s.num_places)
    p = double(s.num_places);
  elseif isfield(s, "petri_net") && isstruct(s.petri_net) && isfield(s.petri_net, "places")
    p = double(s.petri_net.places);
  elseif isfield(s, "petri_net") && isnumeric(s.petri_net) && !isempty(s.petri_net)
    p = double(size(s.petri_net, 1));
  else
    p = 0;
  endif

  % 2. Transitions
  if isfield(s, "num_transitions") && !isempty(s.num_transitions)
    t = double(s.num_transitions);
  elseif isfield(s, "petri_net") && isstruct(s.petri_net) && isfield(s.petri_net, "transitions")
    t = double(s.petri_net.transitions);
  elseif isfield(s, "petri_net") && isnumeric(s.petri_net) && !isempty(s.petri_net)
    t = double((size(s.petri_net, 2) - 1) / 2);
  else
    t = 0;
  endif

  % 3. States (Marking vertices)
  if isfield(s, "num_states") && !isempty(s.num_states)
    st = double(s.num_states);
  elseif isfield(s, "num_vertices") && !isempty(s.num_vertices)
    st = double(s.num_vertices);
  elseif isfield(s, "reachability_graph") && isstruct(s.reachability_graph) && isfield(s.reachability_graph, "num_vertices")
    st = double(s.reachability_graph.num_vertices);
  elseif isfield(s, "vertices") && isnumeric(s.vertices) && !isempty(s.vertices)
    st = double(size(s.vertices, 1));
  elseif isfield(s, "steady_state_probs") && !isempty(s.steady_state_probs)
    st = double(length(s.steady_state_probs));
  else
    st = 0;
  endif

  % 4. Edges
  if isfield(s, "num_edges") && !isempty(s.num_edges)
    ed = double(s.num_edges);
  elseif isfield(s, "reachability_graph") && isstruct(s.reachability_graph) && isfield(s.reachability_graph, "num_edges")
    ed = double(s.reachability_graph.num_edges);
  elseif isfield(s, "edges")
    if iscell(s.edges)
      ed = double(length(s.edges));
    elseif isnumeric(s.edges) && !isempty(s.edges)
      ed = double(size(s.edges, 1));
    else
      ed = 0;
    endif
  else
    ed = 0;
  endif

  % 5. Average markings
  if isfield(s, "average_markings")
    am = s.average_markings;
  elseif isfield(s, "avg_markings")
    am = s.avg_markings;
  else
    am = [];
  endif

  % 6. Steady state probs
  if isfield(s, "steady_state_probs")
    probs = s.steady_state_probs;
  else
    probs = [];
  endif

  % 7. Marking densities
  if isfield(s, "marking_densities")
    dens = s.marking_densities;
  else
    dens = {};
  endif

  % 8. Max tokens
  mt = 0;
  if isfield(s, "vertices") && isnumeric(s.vertices) && !isempty(s.vertices)
    mt = double(max(s.vertices(:)));
  elseif isfield(s, "reachability_graph") && isstruct(s.reachability_graph) && isfield(s.reachability_graph, "vertices") && !isempty(s.reachability_graph.vertices)
    mt = double(max(s.reachability_graph.vertices(:)));
  elseif isfield(s, "petri_net") && isstruct(s.petri_net) && isfield(s.petri_net, "tokens")
    mt = double(max(s.petri_net.tokens(:)));
  elseif !isempty(am)
    mt = double(ceil(max(am(:))));
  endif
endfunction

function ztp = extract_zero_token_prob(dens, num_places)
  ztp = 0.0;
  if isempty(dens)
    return;
  endif

  if isnumeric(dens)
    if size(dens, 2) >= 1
      ztp = mean(dens(:, 1));
    endif
  elseif iscell(dens)
    p_count = length(dens);
    if p_count > 0
      vals = zeros(p_count, 1);
      for p = 1:p_count
        dp = dens{p};
        if iscell(dp) && !isempty(dp)
          vals(p) = double(dp{1});
        elseif isnumeric(dp) && !isempty(dp)
          vals(p) = double(dp(1));
        endif
      endfor
      ztp = mean(vals);
    endif
  endif
endfunction

function s = compute_metric_stats(data)
  data = double(data(:));
  data = data(!isnan(data) & !isinf(data));
  n = length(data);

  if n == 0
    s = empty_metric_stats();
    return;
  endif

  s = struct();
  s.count = n;
  s.mean = mean(data);
  if n > 1
    s.std = std(data);
  else
    s.std = 0.0;
  endif
  s.min = min(data);
  s.max = max(data);

  % Quantiles
  q = quantile(data, [0.25, 0.50, 0.75]);
  s.p25 = q(1);
  s.median = q(2);
  s.p75 = q(3);
  s.iqr = s.p75 - s.p25;

  % Histogram for graphical presentation
  nbins = min(10, length(unique(data)));
  if nbins < 1
    nbins = 1;
  endif

  if s.min == s.max
    s.hist_counts = [n];
    s.hist_centers = [s.min];
    s.hist_edges = [s.min - 0.5, s.max + 0.5];
  else
    [counts, centers] = hist(data, nbins);
    s.hist_counts = counts;
    s.hist_centers = centers;
    s.hist_edges = linspace(s.min, s.max, nbins + 1);
  endif
endfunction

function s = empty_metric_stats()
  s = struct("count", 0, "mean", 0.0, "std", 0.0, "min", 0.0, ...
             "p25", 0.0, "median", 0.0, "p75", 0.0, "max", 0.0, "iqr", 0.0, ...
             "hist_counts", [], "hist_centers", [], "hist_edges", []);
endfunction

