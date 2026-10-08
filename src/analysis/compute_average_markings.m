## -*- texinfo -*-
## @deftypefn {} {[@var{avg_markings}, @var{marking_densities}] =} compute_average_markings (@var{rg}, @var{steady_state_probs})
## @deftypefnx {} {[@var{avg_markings}, @var{marking_densities}] =} compute_average_markings (@var{rg}, @var{steady_state_probs}, @var{force_pure_octave})
## Compute average token counts and probability distributions per place.
##
## Computes expected token occupancy and discrete probability density distributions
## for each place in the Petri net given the steady-state probability distribution
## of the continuous-time Markov chain. Uses high-performance C++ extension
## (@file{compute_average_markings_oct}) when compiled, with an optimized pure Octave fallback.
##
## @table @asis
## @item @var{rg}
## Reachability graph struct containing marking @code{vertices}.
##
## @item @var{steady_state_probs}
## Column vector of length @math{V} with steady-state state probabilities.
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, bypasses compiled oct-file.
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
function [avg_markings, marking_densities] = compute_average_markings(rg, steady_state_probs, force_pure_octave)

  if nargin < 3
    force_pure_octave = false;
  endif

  if rg.num_vertices == 0
    avg_markings = [];
    marking_densities = {};
    return;
  endif

  V = int32(rg.num_vertices);
  P = int32(size(rg.vertices, 2));
  probs = double(steady_state_probs(:));

  if !force_pure_octave && exist("compute_average_markings_oct", "file") == 3
    try
      [avg_markings, marking_densities] = compute_average_markings_oct(int32(rg.vertices), probs, P);
      return;
    catch
      % Fallback to pure Octave if dynamic link or execution fails
    end_try_catch
  endif

  % Vectorized computation of average tokens per place
  avg_markings = (probs' * double(rg.vertices))';

  % Fast computation of token probability densities using column-wise sparse accumulation
  max_p = max(rg.vertices, [], 1);
  marking_densities = cell(P, 1);
  for p = 1:P
    mp = double(max_p(p)) + 1;
    d = full(sparse(double(rg.vertices(:, p)) + 1, 1, probs, mp, 1));
    marking_densities{p} = d';
  endfor
endfunction

