function [avg_markings, marking_densities] = compute_average_markings(rg, steady_state_probs)
  % COMPUTE_AVERAGE_MARKINGS Computes average token counts and probability densities per place.
  %
  % Inputs:
  %   rg                 - Reachability graph struct with vertices matrix
  %   steady_state_probs - Vector of steady-state probabilities (length V)
  %
  % Outputs:
  %   avg_markings       - Column vector of length P with average tokens per place
  %   marking_densities  - Cell array of length P, where cell {p} contains probabilities
  %                        for tokens 0, 1, ..., max_tokens in place p.

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

