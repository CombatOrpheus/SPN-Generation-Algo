## -*- texinfo -*-
## @deftypefn {} {@var{h} =} hash_marking_64 (@var{marking})
## 64-bit avalanche hash matching Go implementation.
##
## Computes a fast 64-bit integer hash for an integer marking vector.
## When compiled, invokes @file{hash_marking_64_oct}.
##
## @table @asis
## @item @var{marking}
## Row or column vector of integers representing place token counts.
## @end table
##
## Returns a 64-bit integer or unique string hash.
##
## @seealso{generate_reachability_graph}
## @end deftypefn
function h = hash_marking_64(marking)

  if exist("hash_marking_64_oct", "file") == 3
    h = hash_marking_64_oct(int32(marking(:)));
    return;
  endif

  % Pure Octave fallback: string-based unique representation
  h = sprintf("%d_", marking(:));
endfunction
