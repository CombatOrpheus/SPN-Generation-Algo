## -*- texinfo -*-
## @deftypefn {} {@var{pn} =} petrinet_prune (@var{pn})
## @deftypefnx {} {@var{pn} =} petrinet_prune (@var{pn}, @var{force_pure_octave})
## Prune Petri net edges while preserving bipartite connectivity.
##
## Prunes excessive arcs from places and transitions (targeting degrees $\le 2$)
## and adds missing connections to eliminate isolated components. Uses high-performance
## C++ extension (@file{petrinet_prune_oct}) when compiled, with an $O(1)$ degree-tracking
## pure Octave fallback.
##
## @table @asis
## @item @var{pn}
## Petri net struct created by @code{petrinet_new}.
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, bypasses the compiled
## C++ oct-file and executes the pure Octave pruning algorithm.
## @end table
##
## Returns pruned Petri net struct @var{pn}.
##
## @seealso{petrinet_new, petrinet_generate_random, petrinet_is_connected}
## @end deftypefn
function pn = petrinet_prune(pn, force_pure_octave)

  if nargin < 2
    force_pure_octave = false;
  endif

  P = pn.places;
  T = pn.transitions;

  if !force_pure_octave && exist("petrinet_prune_oct", "file") == 3
    c_seed = randi(intmax("int32"));
    pn.matrix = petrinet_prune_oct(int32(pn.matrix), int32(P), int32(T), uint32(c_seed));
    return;
  endif

  % Optimized pure Octave implementation with O(1) connectivity tracking
  row_sums = sum(pn.matrix(:, 1:(2 * T)), 2);
  col_sums = sum(pn.matrix(:, 1:(2 * T)), 1);

  % 1. Delete excess edges from places
  for i = 1:P
    if row_sums(i) >= 3
      edge_indices = find(pn.matrix(i, 1:(2 * T)) == 1);
      edge_indices = edge_indices(randperm(length(edge_indices)));
      num_to_try = length(edge_indices) - 2;
      for k = 1:num_to_try
        col_idx = edge_indices(k);
        if col_sums(col_idx) > 1
          pn.matrix(i, col_idx) = 0;
          if !petrinet_is_connected(pn)
            pn.matrix(i, col_idx) = 1;
          else
            row_sums(i) = row_sums(i) - 1;
            col_sums(col_idx) = col_sums(col_idx) - 1;
          endif
        endif
      endfor
    endif
  endfor

  % 2. Delete excess edges from transitions
  for j = 1:(2 * T)
    if col_sums(j) >= 3
      edge_indices = find(pn.matrix(:, j) == 1);
      edge_indices = edge_indices(randperm(length(edge_indices)));
      num_to_try = length(edge_indices) - 2;
      for k = 1:num_to_try
        row_idx = edge_indices(k);
        if row_sums(row_idx) > 1
          pn.matrix(row_idx, j) = 0;
          if !petrinet_is_connected(pn)
            pn.matrix(row_idx, j) = 1;
          else
            row_sums(row_idx) = row_sums(row_idx) - 1;
            col_sums(j) = col_sums(j) - 1;
          endif
        endif
      endfor
    endif
  endfor

  % 3. Vectorized missing connections to transitions
  zero_cols = find(col_sums == 0);
  if !isempty(zero_cols)
    rand_places = randi(P, 1, length(zero_cols));
    idx = sub2ind(size(pn.matrix), rand_places, zero_cols);
    pn.matrix(idx) = 1;
  endif

  % 4. Vectorized missing connections to places
  zero_pre = find(sum(pn.matrix(:, 1:T), 2) == 0);
  if !isempty(zero_pre)
    rand_trans = randi(T, length(zero_pre), 1);
    idx = sub2ind(size(pn.matrix), zero_pre, rand_trans);
    pn.matrix(idx) = 1;
  endif

  zero_post = find(sum(pn.matrix(:, (T + 1):(2 * T)), 2) == 0);
  if !isempty(zero_post)
    rand_trans = randi(T, length(zero_post), 1);
    idx = sub2ind(size(pn.matrix), zero_post, T + rand_trans);
    pn.matrix(idx) = 1;
  endif

endfunction
