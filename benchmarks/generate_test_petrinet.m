function pn = generate_test_petrinet(places, transitions)
  % GENERATE_TEST_PETRINET Predictable test net matching SPN-Algo-Go benchmarks.
  pn = petrinet_new(places, transitions);

  for t = 0:(transitions - 1)
    pre_place = mod(t, places) + 1;
    post_place = mod(t + 1, places) + 1;

    pn.matrix(pre_place, t + 1) = 1;
    pn.matrix(post_place, t + 1 + transitions) = 1;
  endfor

  for p = 0:(places - 1)
    if mod(p, 2) == 0
      pn.matrix(p + 1, 2 * transitions + 1) = 1;
    endif
  endfor

  pn.initial_marking = pn.matrix(:, 2 * transitions + 1);
endfunction
