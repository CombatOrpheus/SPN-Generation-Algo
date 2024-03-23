function new_net = prune_petri(petri_net_matrix, tran_num)
  new_net = dele_edge(petri_net_matrix);
  new_net = add_node(petri_net_matrix, tran_num);
endfunction

function new_net = dele_edge(petri_net_matrix)
  # Exclude the last row
  row_idxs = find(sum(petri_net_matrix(:, 1:end-1), 2) >= 3);
  choices = arrayfun(@random_choice, row_idxs);
  petri_net_matrix(row_idxs, choices) = 0;

  # Exclude the last row
  column_totals = sum(petri_net_matrix(1:end-1, :), 1);
  column_idxs = find(column_totals >= 3);
  for idx = column_idxs
    column = petri_net_matrix(idx, :);
    idxs = find(column == 1);
    choice = random_choice(column(idxs), sum(idxs) - 2);
    column(choice) = 0;
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
