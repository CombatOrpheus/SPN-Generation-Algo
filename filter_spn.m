%% usage: result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
%% Inputs:
%%   petri_matrix: A Petri Net matrix
%%
function result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
  result.valid = false;

  result_reachability = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit);
  result_reachability.bounded && return;
  
  [steady_values, mark_density, mu_mark_nums, lambda] = generate_sgn_task(result_reachability);
  isempty(stead_values) && return;
  
  is_connected_graph(petri_matrix) && return;

  result.petri_net = convert_data(petri_matrix);
  result.reachability_graph_vertices = convert_data(result_reachability.v_list);
  result.reachability_graph_edges = convert_data(result_reachability.edge_list);
  result.arc_transitions_list = convert_data(result_reachability.arctrans_list);
  result.spn_lambda = lambda;
  result.spn_mark_density = mark_density;
  result.spn_all_mus = mu_marks_nums;
  result.spn_mu = sum(mu_marks_nums);
  result.valid = true;
endfunction
