function choice = random_choice(vec, num=1)
  idxs = randi(length(vec), num, 1);
  choice = vec(idxs);
endfunction
