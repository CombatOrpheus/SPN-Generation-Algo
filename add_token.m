function new_net = add_token(petri_matrix)
  choices = randn(rows(petri_matrix)) <= 0.2;
  petri_matrix(choices, end);
  new_net = petri_matrix;
endfunction
