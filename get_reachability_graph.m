%% result_struct = get_reachability_graph(petri_matrix, place_upper_limit, marks_upper_limit)
%%
%% Computes the reachability graph of a Stochastic Petri Net (SPN).
%%
%% A reachability graph represents all possible states (markings) that a
%% Petri net can reach from its initial marking by firing transitions. Each node
%% in the graph is a marking, and an edge represents a transition firing that
%% leads from one marking to another.
%%
%% This function explores the state space of the SPN starting from the initial
%% marking M0. It checks for unboundedness by limiting the number of tokens
%% per place and the total number of markings explored.
%%
%% Inputs:
%%   petri_matrix: The compound matrix representing the SPN. This is a
%%                 pn x (2*tn + 1) matrix with the structure:
%%                 [T_in, T_out, M0], where T_in is the pre-incidence matrix,
%%                 T_out is the post-incidence matrix, and M0 is the initial marking.
%%   place_upper_limit: (Optional) The maximum number of tokens allowed in any
%%                      single place. If exceeded, the net is considered unbounded.
%%                      Default: 10.
%%   marks_upper_limit: (Optional) The maximum number of unique markings to explore.
%%                      If exceeded, the net is considered unbounded. Default: 500.
%%
%% Outputs:
%%   result_struct: A structure containing the results of the analysis.
%%     .v_list: A matrix where each column is a unique marking (vertex) found.
%%     .edge_list: An m x 2 matrix representing the edges of the graph, where m
%%                 is the number of transitions between markings. Each row is
%%                 [source_marking_idx, dest_marking_idx].
%%     .arctrans_list: A list of transitions corresponding to each edge in edge_list.
%%     .bounded: A boolean flag, true if the net is considered bounded within the
%%               given limits, false otherwise.

function result_struct = get_reachability_graph(petri_matrix, place_upper_limit=10, marks_upper_limit=500)
  % --- 1. Deconstruct the input compound matrix ---
  num_transitions = (columns(petri_matrix) - 1) / 2;

  % T_in (A-): Matrix showing tokens consumed by transitions.
  % Rows are places, columns are transitions. T_in(i, j) = 1 means transition j consumes a token from place i.
  T_in = petri_matrix(:, 1:num_transitions);

  % T_out (A+): Matrix showing tokens produced by transitions.
  % T_out(i, j) = 1 means transition j produces a token for place i.
  T_out = petri_matrix(:, (num_transitions+1):end-1);

  % M0: The initial marking (state) of the Petri net.
  % A column vector where M0(i) is the number of tokens in place i.
  M0 = petri_matrix(:, end);

  % C: The incidence matrix, C = T_out - T_in.
  % It represents the net change in tokens for each place when a transition fires.
  C = T_out - T_in;

  % --- 2. Initialize data structures for the graph search ---
  % A list of indices of markings that are new and need to be explored.
  new_markings_list = [1];
  % A counter for the total number of unique markings found so far.
  markings_count = 1;

  % Initialize the result structure.
  result_struct.v_list = [M0]; % The list of unique markings (vertices). Start with M0.
  result_struct.edge_list = []; % The list of edges between markings.
  result_struct.arctrans_list = []; % The list of transitions for each edge.
  result_struct.bounded = true;

  % NOTE on performance: The lists above are grown inside the loop, which can be
  % inefficient in Octave/MATLAB. For better performance with large graphs,
  % pre-allocating these matrices would be a good optimization.

  % --- 3. Explore the state space to build the reachability graph ---
  % The loop continues as long as there are new markings to explore.
  while (~isempty(new_markings_list))
    % Check if the number of markings exceeds the limit.
    if (markings_count > marks_upper_limit)
      result_struct.bounded = false;
      return;
    endif

    % Select a marking to explore from the list of new markings.
    % We process them in order (FIFO), making this a Breadth-First Search.
    current_marking_idx = new_markings_list(1);
    new_markings_list(1) = []; % Remove it from the "to explore" list.
    current_marking = result_struct.v_list(:, current_marking_idx);

    % Find which transitions are enabled for the current marking.
    % A transition 'j' is enabled if the current marking has enough tokens
    % in all of its input places (i.e., M(i) >= T_in(i, j) for all places 'i').
    enabled_transitions = find(all(current_marking >= T_in, 1));

    % For each enabled transition, compute the next marking.
    for trans_idx = enabled_transitions
      % Firing a transition: M_new = M_current + C*t
      % where t is a vector with a 1 at the position of the fired transition.
      % This is equivalent to: M_new = M_current - T_in + T_out
      next_marking = current_marking + C(:, trans_idx);

      % Check if the new marking exceeds the token limit per place.
      if (any(next_marking > place_upper_limit))
        result_struct.bounded = false;
        return;
      endif

      % Check if this `next_marking` has been seen before.
      next_marking_idx = wherevec(next_marking, result_struct.v_list);

      if (next_marking_idx == -1)
        % This is a new, unseen marking.
        markings_count += 1;
        next_marking_idx = markings_count;

        % Add it to the list of vertices (unique markings).
        result_struct.v_list = [result_struct.v_list, next_marking];
        % Add its index to the list of markings to be explored.
        new_markings_list = [new_markings_list, next_marking_idx];
      endif

      % Add an edge to the graph from the current marking to the next one.
      result_struct.edge_list = [result_struct.edge_list; [current_marking_idx, next_marking_idx]];
      % Record which transition corresponds to this edge.
      result_struct.arctrans_list = [result_struct.arctrans_list; trans_idx];
    endfor
  endwhile
endfunction
