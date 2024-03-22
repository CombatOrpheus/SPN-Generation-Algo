function choice = random_choice(vec, num=1)
  idxs = randi(len(vec), num);
  choice = vec(idxs);
endfunction
