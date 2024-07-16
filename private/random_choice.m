## choice = random_choice(vec, num)
## Given a vector, select n random numbers from it. Numbers might be repeated.
function choice = random_choice(vec, num=1)
  idxs = randi(length(vec), num, 1);
  choice = vec(idxs);
endfunction
