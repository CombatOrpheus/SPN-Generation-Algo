%% usage: new_net = prune_petri (petri_net_matrix)
%% Given a Petri Net matrix, randomly change the connections between places and
%% transitions.
%% Inputs:
%%  petri_net_matrix: The petri net compound matrix [A+'; A-'; M0], where A+ and
%%  A- are p x n matrices, where p is the number of places and n is the number
%%  of transitions, and M0 is a tall vector with the initial marking of the net.
%% Outputs:
%%  new_net: A petri net that has 
%%
function new_net = prune_petri(petri_net_matrix)
  new_net = del_edge(petri_net_matrix);
  new_net = add_node(new_net);
endfunction

function new_net = del_edge(petri_net_matrix)
  % Find places that are connected to at least three transitions
  valid_rows = sum(petri_net_matrix(:, 1:end-1), 2);
  row_idxs = find(valid_rows >= 3);
  % Make it so the place is only connected to a single transition.
  % Octave iterates over columns, so we have to transpose the row_idxs
  for row = row_idxs'
    idxs = find(petri_net_matrix(row, 1:end-1) == 1);
    rm_idxs = random_choice(idxs, valid_rows(row) - 2);
    petri_net_matrix(row, rm_idxs) = 0;
  endfor

  % Do the same process for transitions
  column_totals = sum(petri_net_matrix(:, 1:end-1), 1);
  column_idxs = find(column_totals >= 3);
  for column = column_idxs
    idxs = find(petri_net_matrix(:, column) == 1);
    rm_idxs = random_choice(idxs, column_totals(column) - 2);
    petri_net_matrix(rm_idxs, column) = 0;
  endfor
  new_net = petri_net_matrix;
endfunction

function new_net = add_node(petri_net_matrix)
  % Each (transition) column must have at least one connection
  column_idxs = find(all(petri_net_matrix == 0, 1));
  num_rows = rows(petri_net_matrix);
  for idx = column_idxs
    petri_net_matrix(randi(num_rows), idx);
  endfor

  % Each (place) row must have at least one connection.
  num_transitions = (columns(petri_net_matrix) - 1)/2;
  left_matrix = petri_net_matrix(:, 1:num_transitions);
  row_idxs = find(all(petri_net_matrix == 0, 2));
  % If we add 1 on the left, we must also add it to the right
  for row = row_idxs'
    choice = randi(num_transitions, 2, 1);
    petri_net_matrix(row, choice(1)) = 1;
    petri_net_matrix(row + num_transitions, choice(2)) = 1;
  endfor

  new_net = petri_net_matrix;
endfunction
