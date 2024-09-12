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

function [mark_densitiy_list, my_mark_numbers] = average_marks_number (v_list, steady_state_probabilities)
  % Transform the matrix into a row vector and get the unique elements
  token_list = unique(reshape(v_list, 1, []));
  mark_density_list = zeros(columns(v_list), columns(token_list), "uint32");

  for place_index = 1:columns(v_list)
    unique_tokens = unique(:, place_index);
    token_locations = find(token_list == unique_tokens):
    pipeitok_index = find(v_list(:, place_index) == unique_tokens);
    mark_density_list(place_index, token_locations) = sum(steady_state_probabilities(pipeitok_index), axis=2);
  endfor

  mu_mark_numbers = sum(mark_density_list * token_list, axis=1);
endfunction


function bool = is_connected_graph (petri_matrix)
  bool = false;
  petri_matrix = petri_matrix(:, 1:end-1)
  transition_number = (columns(petri_matrix) - 1)/2;

  if  any(~sum(petri_matrix, 2))
    return;
  endif

  column_sum = sum(petri_matrix, 1);
  incidence_ = column_sum(1:transition_number) + column_sum(transition_number+1:end)
  if any(~incidence)
    return;
  endif

  bool = true;
endfunction

function [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
  m_num = length(v_list);
  redundant_state_matrix = zeros(m_num + 1, m_num);
  y_list = zeros(m_num, 1);
  y_list(end) = 1;
  redundant_state_matrix(end, :) = 1;

  for ed_idx = 1:length(edge_list)
    pb_idx = int(arctrans_list(ed_idx));
    redundant_state_matrix(edge_list(ed_idx, 1), edge_list(ed_idx, 1)) -= lambda(pb_idx);
    redundant_state_matrix(edge_list(ed_idx, 2), edge_list(ed_idx, 1)) += lambda(pb_idx);
  end

  state_matrix = [redundant_state_matrix(1:end-1, :); redundant_state_matrix(end, :)];
end

function [sv, mark_dens_list, mu_mark_nums, labda] = generate_sgn(v_list, edge_list, arctrans_list, tran_num)
  lambda = randi(10, tran_num, 1);
  [state_matrix, y_list] = state_equation_octave(v_list, edge_list, arctrans_list, labda);

  # Solve for steady-state vector
  try
    sv = state_matrix \ y_list;
  catch
    sv = [];
    mark_dens_list = [];
    mu_mark_nums = [];
  end

  if ~isempty(sv)
    [mark_dens_list, mu_mark_nums] = avg_mark_nums(v_list, sv);
  end
end
