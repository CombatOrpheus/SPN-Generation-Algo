% result_struct = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit)
% Obtain the reachable graph of a petri net.
% Inputs:
%   petri_matrix: The petri net in compound matrix for [A+';A-';M0].
%   place_upper_limit: The maximum number of tokens in any place before the net
%   is considered unbounded. The default value is 10.
%   marks_upper_limit: The maximum number of markings before considering a net
%   unbouded. The default value is 500.
% Outputs:
%   The results are outputed as a single structure.
%   v_list: The set of vertices of the reachable graph.
%   edge_list: The set of edges of the reachable graph.
%   arctrans_list: The set of arc transitions of the reachable graph.
%   tran_num: The number of transitions on the Petri net.
%   bounded: Whether the Petri net is bounded or unbouded.


function result_struct = get_reachability_graph(petri_matrix, place_upper_limit=10, marks_upper_limit=500)
  % The number of transitions is the number of rows in either A+' or A-'
  tran_num = (rows(petri_matrix) - 1)/2;
  # Tokens needed to enable a transition; they are consumed when fired
  T_in = petri_matrix(:, 1:tran_num);
  # Tokens produced when a transition is fired
  T_out = petri_matrix(:, (tran_num+1):end-1);
  # The initial marking of the Petri Net; the last column of the compound matrix
  M0 = petri_matrix(:, end);
  counter = 0;
  new_list = [0];
  # Construct the Incidence matrix; to compute the new marking, we only need to
  # sum the marking and the column for the fired transition.
  C = T_out - T_in;
  result_struct.v_list = [M0];
  result_struct.edge_list = [];
  result_struct.arctrans_list = [];
  result_struct.tran_num = tran_num;
  result_struct.bounded = true;

  % Continue looping while there are new markings
  while (~isempty(new_list))
    if (counter > marks_upper_limit)
      % Possibly unbounded Petri net
      result_struct.bounded = false; return
    endif

    % Get a random marking from the list; each column is a marking
    new_marking = new_list(:, randi(columns(new_list)));
    [new_markings, enabled_transitions] = enabled_sets(T_in, T_out, result_struct.v_list(new_marking));
    for bs = new_markings
      if (any(bs > place_upper_limit))
	% Possibly unbounded Petri net
        result_struct.bounded = false; return;
      else
        for ent_idx = enabled_transitions
	  % Row vector
          t = zeros(tran_num, 1, "uint32");
          t(ent_idx) = 1;
          marking = result_struct.v_list(:, new_marking) + sum(C * t, 2);
          new_marking_idx = wherevec(marking, result_struct.v_list);
          if (new_marking_idx == -1)
            counter += 1;
            result_struct.v_list = [result_struct.v_list; counter];
            new_list = [new_list; counter];
            result_struct.edge_list = [result_struct.edge_list; [new_marking, counter]];
          else
            result_struct.edge_list = [result_struct.edge_list; [new_m, new_marking_idx]];
          endif

          result_struct.arctrans_list = [result_struct.arctrans_list; ent_idx];
        endfor
        new_list = new_list(new_list != new_marking);
      endif
    endfor
  endwhile
endfunction

function row_index = wherevec(row_vec, matrix)
  % Find the index of the first row in a matrix that is equal to the given
  % vector; if none are equal, return -1.
  row_index = -1;
  % Broadcasted operation
  equal_matrix = (matrix == row_vec);
  % First, check which rows are equal to the vector, then, if any are equal
  % get their index.
  if any(all(equal_matrix, 2))
    row_index = find(all(equal_matrix, 2), 1);
  endif
endfunction

function [new_markings, enabled_transitions] = enabled_sets(A1, A2, M)
  % Given the Pre-set and the current marking, find which transitions (columns)
  % are enabled.
  % Inputs:
  %   A1: The transposed Petri net pre-sets, where each column is a transition.
  %   A2: The transposed Petri net post-sets, where each column is a transition.
  %   M: A single vector representing the current marking; a column vector.
  % Outputs:
  %   new_markings: a matrix containing the new markings generated after firing
  %   all enabled transitions; each column is a new marking.
  %   enabled_transitions: a vector containing the index of the enabled
  %   transitions, in the form of a row vector'.

  % First, we have to check which transitions (columns on A1) can be enabled,
  % given the current marking (tokens in each place); the marking (M) must have
  % at least as many tokens in each input place in order to be enable a
  % transition.
  enabled_transitions = find(all(M >= A1, 1));
  % Then, for each enabled transition (column), consume the input tokens (-A1)
  % and generate the output tokens (+A2).
  new_markings = M - A1(:, enabled_transitions) + A2(:, enabled_transitions);
endfunction
