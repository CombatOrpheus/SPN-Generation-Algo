% result_struct = get_arrivable_graph(petri_matrix, place_upper_limit, marks_upper_limit)
% Obtain the reachable graph of the petri net.
% Inputs:
%   petri_matrix: The petri net in compound matrix for [A+';A-':M0].
function result_struct = get_arrivable_graph(...
  petri_matrix, place_upper_limit=10, marks_upper_limit=500)
  tran_num = (rows(petri_matrix) - 1)/2;
  # Tokens needed to enable a transition; they are consumed when fired
  T_in = petri_matrix(:, 1:tran_num);
  # Tokens produced when a transition is fired
  T_out = petri_matrix(:, (tran_num+1):end-1);
  # The initial marking of the Petri Net
  M0 = petri_matrix(:, end);
  counter = 0;
  new_list = [0];
  # Construct the
  C = T_out - T_in;
  result_struct.v_list = [M0];
  result_struct.edge_list = [];
  result_struct.arctrans_list = [];
  result_struct.tran_num = tran_num;
  result_struct.bound_flag = true;

  while (~isempty(new_list))
    if (counter > marks_upper_limit)
      result_struct.bound_flag = false; return;
    endif

    new_marking = random_choice(new_list);
    [graph_enabled_sets, transition_sets] = ...
      enable_sets(T_in, T_out, result_struct.v_list(new_marking);
    for bs = graph_enabled_sets
      if (any(bs > place_upper_limit)
        result_struct.bound_flag = false; return;
      else
        for ent_idx = transition_sets
          t = zeros(tran_num, "unit8");
          t[ent_idx] = 1;
          marking = result_struct.v_list(new_marking) + dot(C, t);
          new_marking_idx = wherevec(marking, result_struct.v_list);
          if (new_marking_idx == -1)
            counter += 1;
            result_struct.v_list = [result_struct.v_list; counter];
            new_list = [new_list; counter];
            result_struct.edge_list = ...
              [result_struct.edge_list; [new_marking, counter]];
          else
            result_struct.edge_list = ...
              [result_struct.edge_list; [new_m, new_marking_idx]];
          endif

          result_struct.arctrans_list = ...
            [result_struct.arctrans_list; ent_idx];
        endfor
        new_list = new_list(new_list != new_marking);
      endif
    endfor
  endwhile
endfunction

function vec = wherevec(row_vec, matrix)
  vec = -1;
  idxs = ~all(matrix - row_vec, 1);
  if ~isempty(idxs)
    vec = idxs[1];
  endif
endfunction

function [ena_mlist, ena_list] = enable_sets(A1, A2, M):
  ena_list = [];
  ena_mlist = [];
  for i = 1:rows(A1)
    % Pre-set
    pro_idx = find(A1(:, i) == 1);
    m_token = M(pro_idx);
    m_enable = find(m_token == 0);
    if (numel(m_enable) == numel(m_token))
      ena_list = [ena_list ; i];
      # Update the marking; subtract 1 from the pre-set and add 1 to the
      # post-set
      M(pro_idx) -= 1;
      % Post-set
      post_idx = find(A2(:, i) == 1);
      M(post_idx) += 1;
      ena_mlistlist = [ena_mlist; M];
    endif
  endfor
endfunction
