function h = hash_marking_64(marking)
  % HASH_MARKING_64 64-bit avalanche hash matching Go's hashMarking64.
  %
  % Inputs:
  %   marking - Row or column vector of integers
  %
  % Outputs:
  %   h - String or uint64 representation of 64-bit hash

  if exist("hash_marking_64_oct", "file") == 3
    h = hash_marking_64_oct(int32(marking(:)));
    return;
  endif

  % Pure Octave fallback: string-based unique representation
  h = sprintf("%d_", marking(:));
endfunction
