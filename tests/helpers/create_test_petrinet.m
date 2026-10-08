## -*- texinfo -*-
## @deftypefn {} {@var{pn} =} create_test_petrinet (@var{places}, @var{transitions})
## Generate a deterministic, connected Petri net fixture for tests and benchmarks.
##
## Constructs a ring topology connecting transition @var{t} from place @var{t} to
## place @var{t+1}, placing tokens on alternate places.
##
## Returns struct @var{pn}.
##
## @seealso{petrinet_new, petrinet_is_connected}
## @end deftypefn
function pn = create_test_petrinet(places, transitions)
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
