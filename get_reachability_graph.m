%% result_struct = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit)
%%
%% Computes the reachability graph of a Stochastic Petri Net (SPN).
%%
%% A reachability graph is a directed graph that represents all possible states
%% (markings) that a Petri net can reach from its initial marking by firing
%% sequences of transitions. Each node (vertex) in the graph is a unique marking,
%% and each directed edge represents a transition firing that leads from one
%% marking to another.
%%
%% This function performs a breadth-first search of the state space, starting
%% from the initial marking M0. It systematically explores new markings by firing
%% all enabled transitions from the current set of known markings. To prevent
%% infinite exploration of unbounded nets, the function includes checks to limit
%% the maximum number of tokens per place and the total number of markings explored.
%%
%% Inputs:
%%   petri_matrix: The compound matrix representing the SPN. This is a
%%                 pn x (2*tn + 1) matrix with the structure:
%%                 [T_in, T_out, M0], where T_in is the pre-incidence matrix,
%%                 T_out is the post-incidence matrix, and M0 is the initial marking.
%%
%%   place_upper_limit: (Optional) The maximum number of tokens allowed in any
%%                      single place. If any explored marking exceeds this limit,
%%                      the exploration stops, and the net is flagged as unbounded.
%%                      Default: 10.
%%
%%   marks_upper_limit: (Optional) The maximum number of unique markings to explore.
%%                      If the number of discovered markings exceeds this limit,
%%                      the exploration stops, and the net is flagged as unbounded.
%%                      Default: 500.
%%
%% Outputs:
%%   result_struct: A structure containing the results of the graph computation.
%%     .v_list: A matrix where each column represents a unique marking (vertex)
%%              found during the exploration. The number of rows equals the
%%              number of places in the net.
%%     .edge_list: An m x 2 matrix representing the directed edges of the graph,
%%                 where m is the total number of state transitions found. Each
%%                 row is a [source_marking_idx, dest_marking_idx] pair, where the
%%                 indices correspond to columns in `v_list`.
%%     .arctrans_list: A column vector of length m, where each element is the
%%                     index of the transition that fired to create the
%%                     corresponding edge in `edge_list`.
%%     .bounded: A boolean flag. It is `true` if the exploration completed without
%%               exceeding the specified limits, and `false` otherwise.

function result_struct = get_reachability_graph(petri_matrix, place_upper_limit=10, marks_upper_limit=500)
  % --- 1. Deconstruct the input compound matrix ---
  num_places = rows(petri_matrix);
  num_transitions = (columns(petri_matrix) - 1) / 2;
  T_in = petri_matrix(:, 1:num_transitions);
  T_out = petri_matrix(:, (num_transitions+1):end-1);
  M0 = petri_matrix(:, end);
  C = T_out - T_in;

  % --- 2. Initialize data structures for the graph search ---
  new_markings_list = [1];
  markings_count = 1;
  edge_count = 0;

  % Use a hash map for efficient lookup of seen markings.
  % The value type is 'any' to allow storing a list of indices for collision handling.
  markings_map = containers.Map('KeyType', 'double', 'ValueType', 'any');
  m0_key = hash_marking(M0);
  markings_map(m0_key) = [1]; % Store as a list

  % Pre-allocate memory for performance.
  prealloc_size = min(marks_upper_limit, 1000);
  v_list = zeros(num_places, prealloc_size);
  edge_list = zeros(prealloc_size * 5, 2); % Guessing 5 edges per marking on avg.
  arctrans_list = zeros(prealloc_size * 5, 1);

  v_list(:, 1) = M0;
  result_struct.bounded = true;

  % --- 3. Explore the state space to build the reachability graph ---
  while (~isempty(new_markings_list))
    if (markings_count > marks_upper_limit)
      result_struct.bounded = false;
      break; % Exit loop, then trim matrices.
    endif

    current_marking_idx = new_markings_list(1);
    new_markings_list(1) = [];
    current_marking = v_list(:, current_marking_idx);

    enabled_transitions = find(all(current_marking >= T_in, 1));

    for trans_idx = enabled_transitions
      next_marking = current_marking + C(:, trans_idx);

      if (any(next_marking > place_upper_limit))
        result_struct.bounded = false;
        break; % Exit inner loop
      endif

      % Check if this `next_marking` has been seen before using the hash map.
      next_marking_key = hash_marking(next_marking);
      next_marking_idx = -1; % Sentinel value

      if isKey(markings_map, next_marking_key)
        % Hash collision is possible. Verify with the actual markings.
        colliding_indices = markings_map(next_marking_key);
        for idx = colliding_indices
          if isequal(v_list(:, idx), next_marking)
            % Found an exact match. The marking has been seen before.
            next_marking_idx = idx;
            break;
          endif
        endfor
      endif

      if next_marking_idx == -1
        % This is a new, unseen marking (or a hash collision with a new marking).
        markings_count += 1;

        % Resize v_list if needed
        if markings_count > columns(v_list)
            v_list = [v_list, zeros(num_places, columns(v_list))];
        endif

        next_marking_idx = markings_count;
        v_list(:, next_marking_idx) = next_marking;
        new_markings_list = [new_markings_list, next_marking_idx];

        % Add the new index to the map.
        if isKey(markings_map, next_marking_key)
            % Append to the list of colliding indices.
            markings_map(next_marking_key) = [markings_map(next_marking_key), next_marking_idx];
        else
            % No collision, create a new list.
            markings_map(next_marking_key) = [next_marking_idx];
        endif
      endif

      edge_count += 1;
      % Resize edge lists if needed
      if edge_count > rows(edge_list)
          edge_list = [edge_list; zeros(rows(edge_list), 2)];
          arctrans_list = [arctrans_list; zeros(rows(arctrans_list), 1)];
      endif

      % Add an edge to the graph.
      edge_list(edge_count, :) = [current_marking_idx, next_marking_idx];
      arctrans_list(edge_count) = trans_idx;
    endfor
    if ~result_struct.bounded, break; end % Exit outer loop
  endwhile

  % --- 4. Finalize results ---
  % Trim the pre-allocated matrices to their actual size.
  result_struct.v_list = v_list(:, 1:markings_count);
  result_struct.edge_list = edge_list(1:edge_count, :);
  result_struct.arctrans_list = arctrans_list(1:edge_count);
endfunction