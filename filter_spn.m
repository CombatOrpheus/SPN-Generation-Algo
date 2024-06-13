%% usage: result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
%% Inputs:
%%   petri_matrix: A Petri Net matrix
%%
function result = filter_spn (petri_matrix, place_upper_bound=10, marks_lower_limit=4, marks_upper_limit=500)
  result.valid = false;

  is_connected_graph(petri_matrix) && return;

  result_reachability = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit);
  result_reachability.bounded && return;
  
  [steady_values, mark_density, mu_mark_nums, lambda] = generate_sgn_task(result_reachability);
  isempty(stead_values) && return;
  
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

function bool = is_connected_graph (petri_matrix)
  bool = false;
  % The last column is the current marking of the Petri net, so we can remove it
  petri_matrix = petri_matrix(:, 1:end-1)
  transition_number = (columns(petri_matrix) - 1)/2;
  % If, for a given place, no transitions change its contents, the graph is not
  % connected. Here, we sum over the rows of the matrix and then invert the
  % resulting vector so that the any function can detect rows that summed to
  % zero.
  any(~sum(petri_matrix, 2)) && return;
  % Likewise, if a transition does not change the values of any places, the
  % graph is not connected. For this, we sum over the columns of the matrix, and
  % then sum 1:transition_number columns with transition_number:end to get the
  % changes for each transition.
  column_sum = sum(petri_matrix, 1);
  any(~(column_sum(1:transition_number) + column_sum(transition_number:end))) && return;
  bool = true;
endfunction
