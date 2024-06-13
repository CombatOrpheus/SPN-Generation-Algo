function new_net = add_token(petri_matrix)
  choices = rand(rows(petri_matrix)) <= 0.2;
  petri_matrix(choices, end);
  new_net = petri_matrix;
endfunction
