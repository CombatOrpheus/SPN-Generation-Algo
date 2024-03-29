function new_net = prune_petri(petri_net_matrix, tran_num)
  new_net = del_edge(petri_net_matrix);
  new_net = add_node(petri_net_matrix, tran_num);
endfunction

function new_net = del_edge(petri_net_matrix)
  row_length = columns(petri_net_matrix) - 1;
  # Find the rows that move at least three tokens, excluding the last column,
  # as it represents the net marking.
  row_totals = sum(petri_net_matrix(:, 1:end-1), 2);
  row_idxs = find(row_totals >= 3);
  # Select sum - 2 random indexes from each row and set them to 0
  for row = row_idxs
    idxs = find(petri_net_matrix(:, row) == 1);
    rm_idxs = random_choice(idxs, row_totals(i) - 2);
    petri_net_matrix(row, rm_idxs) = 0
  endfor

  # Do the same process, but for the columns this time.
  column_totals = sum(petri_net_matrix(:, 1:end-1), 1);
  column_idxs = find(column_totals >= 3);
  for column = column_idxs
    idxs = find(petri_net_matrix(column, :) == 1);
    rm_idxs = random_choice(idxs, column_totals - 2);
    petri_net_matrix(rm_idxs, column) = 0;
  endfor
  new_net = petri_net_matrix;
endfunction

function new_net = add_node(petri_net_matrix, tran_num)
  left_matrix = petri_net_matrix(:, 1:tran_num);
  right_matrix = petri_net_matrix(:, (tran_num + 1):(end - 1));
  column_size = length(petri_net_matrix(:, 1));

  # Each column must have at least 1
  column_idxs = sum(petri_net_matrix(:, 1:end-1), 1) == 0;
  choices = randi(column_size, sum(column_idxs));
  petri_net_matrix(choices, column_idxs) = 1

  # For each row, both the left_matrix and right_matrix must have at least 1
  # token each
  row_idxs = ~any(left_matrix, 2);
  choices = randi(column_size, numel(row_idxs));
  left_matrix(row_idxs, choices) = 1;

  row_idxs = ~any(right_matrix, 2);
  choices = randi(column_size, numel(row_idxs));
  right_matrix(row_idxs, choices) = 1;
  new_net = petri_net_matrix;
endfunction
