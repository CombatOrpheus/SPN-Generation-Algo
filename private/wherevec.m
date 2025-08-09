%% col_index = wherevec(col_vec, matrix)
%%
%% Finds the index of the first column in a matrix that is equal to a given vector.
%%
%% This is a helper function used to check if a newly computed marking of a
%% Petri net has been seen before.
%%
%% Inputs:
%%   col_vec: A column vector to search for.
%%   matrix: A matrix to search within, where each column is compared against
%%           col_vec.
%%
%% Outputs:
%%   col_index: The 1-based index of the first matching column in the matrix.
%%              Returns -1 if no matching column is found.

function col_index = wherevec(col_vec, matrix)
  col_index = -1;
  % Create a logical row vector indicating which columns match the vector.
  column_equal_to_vector = all(matrix == col_vec, 1);
  if any(column_equal_to_vector)
    % Find the index of the first '1' in the logical vector.
    col_index = find(column_equal_to_vector, 1);
  endif
endfunction
