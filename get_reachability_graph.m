%% result_struct = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit)
%% Obtain the reachable graph of a petri net.
%% Inputs:
%%   petri_matrix: The petri net in compound matrix for [A+';A-';M0].
%%   place_upper_limit: The maximum number of tokens in any place before the net
%%   is considered unbounded. The default value is 10.
%%   marks_upper_limit: The maximum number of markings before considering a net
%%   unbouded. The default value is 500.
%% Outputs:
%%   The results are outputed as a single structure.
%%   v_list: The set of vertices of the reachable graph.
%%   edge_list: The set of edges of the reachable graph.
%%   arctrans_list: The set of arc transitions of the reachable graph.
%%   tran_num: The number of transitions on the Petri net.
%%   bounded: Whether the Petri net is bounded or unbouded.
%%
function result_struct = get_reachability_graph(petri_matrix, place_upper_limit=10, marks_upper_limit=500)
  % The number of transitions is the number of rows in either A+' or A-'
  tran_num = (columns(petri_matrix) - 1)/2;
  T_in = petri_matrix(:, 1:tran_num);           % Tokens consumed when firing
  T_out = petri_matrix(:, (tran_num+1):end-1);  % Tokens produced when firing
  M0 = petri_matrix(:, end);                    % Initial Marking
  counter = 1;
  new_list = [1];
  C = T_out - T_in;                             % Incidence Matrix

  result_struct.v_list = [M0];
  result_struct.edge_list = [];
  result_struct.arctrans_list = [];
  result_struct.bounded = true;
  % Loop while there are new markings to explore
  while (~isempty(new_list))
    if (counter > marks_upper_limit) % Possibly unbounded Petri net
      result_struct.bounded = false; return
    endif
    % Get a random marking from the list; each column is a marking
    choice = randi(rows(new_list));
    idx = new_list(choice);
    [new_markings, enabled_transitions] = enabled_sets(T_in, T_out, result_struct.v_list(:, idx));
    new_list(choice) = [];
    for bs = new_markings
      if (any(bs > place_upper_limit)) % Possibly unbounded Petri net
        result_struct.bounded = false; return;
      else
        for ent_idx = enabled_transitions
	  % Compute the value of the new marking after firing a transition
          marking = result_struct.v_list(:, choice) + C(:, ent_idx);
          new_marking_idx = wherevec(marking, result_struct.v_list);
	  % If marking has not been seen before, take note of it
          if (new_marking_idx == -1)
            counter += 1;
            result_struct.v_list = [result_struct.v_list, marking];
            new_list = [new_list, counter];
            result_struct.edge_list = [result_struct.edge_list; [idx, counter]];
          else
            result_struct.edge_list = [result_struct.edge_list; [idx, new_marking_idx]];
          endif
          result_struct.arctrans_list = [result_struct.arctrans_list; ent_idx];
        endfor
      endif
    endfor
  endwhile
endfunction

%% col_index = wherevec(col_vec, matrix)
%% Returns the index of the first column in the matrix that is equal to vector
function col_index = wherevec(col_vec, matrix)
  col_index = -1;
  column_equal_to_vector = all(matrix == col_vec, 1);
  if any(column_equal_to_vector)
    col_index = find(all(equal_matrix, 2), 1);
  endif
endfunction

%% [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
%% Given the current marking, find which transitions are enabled
function [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
  enabled_transitions = find(all(M >= pre_set, 1));
  new_markings = M - pre_set(:, enabled_transitions) + post_set(:, enabled_transitions);
endfunction
