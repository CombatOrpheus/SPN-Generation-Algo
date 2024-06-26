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
  % Find the rows that move at least three tokens. The last column represents
  % the net marking, so we can discard it.
  row_totals = sum(petri_net_matrix(:, 1:end-1), 2);
  row_idxs = find(row_totals >= 3);
  % Select sum - 2 random indexes from each row and set them to 0 so that they
  % only move one token. Octave iterates over columns, so we have to transpose
  % the row_idxs since it is a column vector.
  for row = row_idxs'
    idxs = find(petri_net_matrix(row, 1:end-1) == 1);
    rm_idxs = random_choice(idxs, row_totals(row) - 2);
    petri_net_matrix(row, rm_idxs) = 0;
  endfor

  % Do the same process, but for the columns this time.
  column_totals = sum(petri_net_matrix(:, 1:end-1), 1);
  column_idxs = find(column_totals >= 3);
  % column_idxs is already a row vector, so there is no need to transpose it.
  for column = column_idxs
    idxs = find(petri_net_matrix(:, column) == 1);
    rm_idxs = random_choice(idxs, column_totals(column) - 2);
    petri_net_matrix(rm_idxs, column) = 0;
  endfor
  new_net = petri_net_matrix;
endfunction

function new_net = add_node(petri_net_matrix)
  column_size = (columns(petri_net_matrix) - 1)/2;
  % Each transition must move at least one token, so we need to find columns
  % whose elements are all zero. The last column contains the marking, so we
  % discard it.
  column_idxs = find(all(~petri_net_matrix(:, 1:end-1), 1));
  % If no elements match, the find function returns an empty matrix.
  if (~isempty(column_idxs)
    choices = randi(column_size, sum(column_idxs));
    petri_net_matrix(choices, column_idxs) = 1;
  endif

  tran_num = (columns(petri_net_matrix) - 1)/2;
  left_matrix = petri_net_matrix(:, 1:tran_num);
  right_matrix = petri_net_matrix(:, (tran_num + 1):(end - 1));
  % Each row in the left matrix must move at least one token, so we find the
  % rows whose elements are all zero.
  row_idxs = all(~left_matrix, 2);
  if (~isempty(row_idxs))
    choices = randi(column_size, numel(row_idxs));
    left_matrix(row_idxs, choices) = 1;
  endif
  % The same thing for the right matrix.
  row_idxs = all(~right_matrix, 2);
  if (~isempty(row_idxs))
    choices = randi(column_size, numel(row_idxs));
    right_matrix(row_idxs, choices) = 1;
  endif
  % Concatenate these matrices horizontaly. We also need to add the initial
  % marking back into this matrix.
  new_net = [left_matrix, right_matrix, petri_net_matrix(:, end)];
endfunction
