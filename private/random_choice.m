function choice = random_choice(vec, num=1)
  idxs = randi(length(vec), num);
  choice = vec(idxs);
endfunction
