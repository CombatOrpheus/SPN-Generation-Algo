## -*- texinfo -*-
## @deftypefn {} {[@var{avg_markings}, @var{marking_densities}] =} compute_average_markings (@var{rg}, @var{steady_state_probs})
## Compute average token counts and probability distributions per place.
##
## Computes expected token occupancy and discrete probability density distributions
## for each place in the Petri net given the steady-state probability distribution
## of the continuous-time Markov chain.
##
## @table @asis
## @item @var{rg}
## Reachability graph struct containing marking @code{vertices}.
##
## @item @var{steady_state_probs}
## Column vector of length @math{V} with steady-state state probabilities.
## @end table
##
## Outputs:
## @table @asis
## @item @var{avg_markings}
## Column vector of length @math{P} containing average token counts for each place.
##
## @item @var{marking_densities}
## Cell array of length @math{P}, where entry @math{\{p\}} contains a vector of
## probabilities for token counts @math{0, 1, \dots, \max(\mathrm{tokens})}.
## @end table
##
## @seealso{solve_steady_state, generate_reachability_graph}
## @end deftypefn
function [avg_markings, marking_densities] = compute_average_markings(rg, steady_state_probs)

  if rg.num_vertices == 0
    avg_markings = [];
    marking_densities = {};
    return;
  endif

  V = rg.num_vertices;
  P = size(rg.vertices, 2);
  probs = steady_state_probs(:);

  % Vectorized computation of average tokens per place
  avg_markings = (probs' * double(rg.vertices))';

  % Fast computation of token probability densities using 2D accumarray
  max_p = max(rg.vertices, [], 1);
  max_tok = max(max_p) + 1;
  D = accumarray([rg.vertices(:) + 1, repelem(1:P, V)'], repmat(probs, P, 1), [max_tok, P]);

  marking_densities = cell(P, 1);
  for p = 1:P
    marking_densities{p} = D(1:(max_p(p) + 1), p)';
  endfor
endfunction

