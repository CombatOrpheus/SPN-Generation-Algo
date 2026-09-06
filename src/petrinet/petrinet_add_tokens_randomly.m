## -*- texinfo -*-
## @deftypefn {} {@var{pn} =} petrinet_add_tokens_randomly (@var{pn})
## Vectorized addition of tokens to places in a Petri net.
##
## Adds 1 token to each place with independent 30% probability without interpreted loops.
## Updates both @code{pn.matrix} initial marking column and @code{pn.initial_marking}.
##
## @table @asis
## @item @var{pn}
## Petri net struct created by @code{petrinet_new}.
## @end table
##
## Returns updated Petri net struct @var{pn}.
##
## @seealso{petrinet_new, petrinet_generate_random}
## @end deftypefn
function pn = petrinet_add_tokens_randomly(pn)

  P = pn.places;
  T = pn.transitions;
  m0_col = 2 * T + 1;

  % Vectorized addition: rand(P, 1) <= 0.3 generates a boolean mask
  pn.matrix(:, m0_col) = pn.matrix(:, m0_col) + int32(rand(P, 1) <= 0.3);
  pn.initial_marking = pn.matrix(:, m0_col);
endfunction
