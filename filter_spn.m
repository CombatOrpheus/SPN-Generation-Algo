%% result = filter_spn(petri_matrix, place_upper_bound, marks_lower_limit, marks_upper_limit)
%%
%% Filters and analyzes a Stochastic Petri Net (SPN) to determine its validity.
%%
%% This function serves as a primary quality gate for generated SPNs. It takes
%% a candidate SPN and subjects it to a series of critical checks. If the SPN
%% fails any of these checks (e.g., it is disconnected or unbounded), the
%% filtering process is halted, and the SPN is marked as invalid.
%%
%% For SPNs that pass all checks, the function proceeds to compute detailed
%% steady-state analysis, providing valuable metrics about the net's behavior.
%%
%% The checks performed are:
%% 1. Connectivity: Ensures the SPN does not have any isolated places or transitions.
%% 2. Boundedness: Computes the reachability graph to ensure the net does not grow
%%    indefinitely.
%% 3. Solvability: Ensures that the underlying Continuous-Time Markov Chain (CTMC)
%%    can be solved to find a steady-state distribution.
%%
%% Inputs:
%%   petri_matrix: The compound matrix of the SPN to analyze. This is a
%%                 pn x (2*tn + 1) matrix structured as [T_in, T_out, M0].
%%
%%   place_upper_bound: (Optional) The maximum number of tokens allowed in any
%%                      single place during the reachability analysis. If a marking
%%                      exceeds this, the net is considered unbounded. Default: 10.
%%
%%   marks_lower_limit: (Optional) This parameter is included for compatibility
%%                      with the original benchmark specification but is not
%%                      currently used in this implementation. Default: 4.
%%
%%   marks_upper_limit: (Optional) The maximum number of unique markings to explore
%%                      during reachability analysis. If the graph exceeds this
%%                      size, the net is considered unbounded. Default: 500.
%%
%% Outputs:
%%   result: A structure containing the analysis results.
%%     .valid: A boolean, `true` if the SPN passed all filters, `false` otherwise.
%%     .petri_net: The original `petri_matrix` that was analyzed.
%%     .reachability_graph_vertices: A matrix where each column is a unique,
%%                                   reachable marking (a vertex in the graph).
%%     .reachability_graph_edges: An m x 2 matrix listing the edges of the
%%                                reachability graph, where each row is a
%%                                [source_idx, destination_idx] pair.
%%     .arc_transitions_list: A vector where each element corresponds to an edge
%%                            and indicates which transition fired.
%%     .spn_lambda: The vector of random firing rates used for the analysis.
%%     .spn_mark_density: A matrix describing the probability of finding a
%%                        certain number of tokens in each place.
%%     .spn_all_mus: A vector containing the average token count (mu) for each
%%                   place at steady state.
%%     .spn_mu: The sum of the average token counts over all places.

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