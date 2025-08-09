%% result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
%%
%% Filters and analyzes a Stochastic Petri Net (SPN).
%%
%% This function acts as a high-level filter. It takes an SPN and subjects it
%% to a series of checks and analyses. If the SPN fails any check (e.g., it's
%% disconnected, unbounded), the process stops. If it passes all checks, the
%% function returns a structure with detailed analysis results.
%%
%% Inputs:
%%   petri_matrix: The compound matrix of the SPN to analyze.
%%   place_upper_bound: (Optional) Max tokens per place for boundedness check.
%%   marks_lower_limit: (Optional) This parameter is not currently used.
%%   marks_upper_limit: (Optional) Max markings to explore for boundedness check.
%%
%% Outputs:
%%   result: A structure containing the analysis results.
%%     .valid: `true` if the SPN passed all filters, `false` otherwise.
%%     .petri_net: The original petri_matrix.
%%     .reachability_graph_vertices: The vertices of the reachability graph.
%%     .reachability_graph_edges: The edges of the reachability graph.
%%     .arc_transitions_list: The transitions for each edge.
%%     .spn_lambda: The firing rates used for steady-state analysis.
%%     .spn_mark_density: The marking density for each place.
%%     .spn_all_mus: The average token count (mu) for each place.
%%     .spn_mu: The sum of average token counts across all places.

function result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
  % Initialize the result structure with 'valid = false'.
  % It will be set to 'true' only if all checks pass.
  result.valid = false;
  num_transitions = (columns(petri_matrix) - 1) / 2;

  % --- Filter 1: Check for isolated nodes ---
  if ~has_no_isolated_nodes(petri_matrix)
    return; % Stop if the SPN has disconnected parts.
  endif

  % --- Filter 2: Check for boundedness ---
  % Compute the reachability graph.
  result_reachability = get_reachability_graph(petri_matrix, place_upper_bound, marks_upper_limit);
  if ~result_reachability.bounded
    return; % Stop if the SPN is unbounded.
  endif
  
  % --- Analysis: Compute Steady-State Properties ---
  % This involves generating random firing rates (lambdas) and solving the underlying
  % Continuous-Time Markov Chain.
  [steady_values, mark_density, mu_mark_nums, lambda] = ...
    generate_steady_state_info(result_reachability, num_transitions);
  
  if isempty(steady_values)
    return; % Stop if a steady-state solution could not be found.
  endif

  % --- All filters passed. Populate the result structure. ---
  result.petri_net = petri_matrix;
  result.reachability_graph_vertices = result_reachability.v_list;
  result.reachability_graph_edges = result_reachability.edge_list;
  result.arc_transitions_list = result_reachability.arctrans_list;
  result.spn_lambda = lambda;
  result.spn_mark_density = mark_density;
  result.spn_all_mus = mu_mark_nums;
  result.spn_mu = sum(mu_mark_nums);
  result.valid = true;
endfunction
