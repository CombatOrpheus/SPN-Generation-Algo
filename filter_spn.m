%% result = filter_spn(petri_matrix, place_upper_bound, marks_lower_limit, marks_upper_limit, solver)
%%
%% Filters and analyzes a Stochastic Petri Net (SPN) to determine its validity.
%%
%% This function serves as a primary quality gate for generated SPNs. It takes
%% a candidate SPN and subjects it to a series of critical checks. If the SPN
%% fails any of these checks (e.g., it is disconnected or unbounded), the
%% filtering process is halted, and the SPN is marked as invalid.
%%
%% For SPNs that pass all checks, it computes detailed steady-state analysis,
%% allowing the user to select the solver for performance tuning.
%%
%% The checks performed are:
%% 1. Connectivity: Ensures the SPN is connected.
%% 2. Boundedness: Computes the reachability graph to ensure the net is bounded.
%% 3. Solvability: Ensures the underlying CTMC can be solved.
%%
%% Inputs:
%%   petri_matrix: The compound matrix of the SPN, structured as [T_in, T_out, M0].
%%
%%   place_upper_bound: (Optional) Max tokens per place for reachability analysis.
%%                      Default: 10.
%%
%%   marks_lower_limit: (Optional) Not currently used. Default: 4.
%%
%%   marks_upper_limit: (Optional) Max markings for reachability analysis.
%%                      Default: 500.
%%
%%   solver: (Optional) A string specifying the solver for steady-state analysis.
%%           Can be 'exact' or an iterative solver name like 'gmres'.
%%           Default: 'exact'.
%%
%% Outputs:
%%   result: A structure containing the analysis results.
%%     .valid: A boolean, `true` if the SPN passed all filters.
%%     .petri_net: The original `petri_matrix`.
%%     .reachability_graph_vertices: Matrix of unique reachable markings.
%%     .reachability_graph_edges: Edge list of the reachability graph.
%%     .arc_transitions_list: Vector mapping edges to transitions.
%%     .spn_lambda: The random firing rates used.
%%     .spn_mark_density: Probability density of tokens in places.
%%     .spn_all_mus: Average token count (mu) for each place.
%%     .spn_mu: Sum of average token counts over all places.

function result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500, solver='exact')
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
  % Continuous-Time Markov Chain using the specified solver.
  [steady_values, mark_density, mu_mark_nums, lambda] = ...
    generate_steady_state_info(result_reachability, num_transitions, solver);
  
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