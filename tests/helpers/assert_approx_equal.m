## -*- texinfo -*-
## @deftypefn {} {} assert_approx_equal (@var{actual}, @var{expected})
## @deftypefnx {} {} assert_approx_equal (@var{actual}, @var{expected}, @var{tol})
## @deftypefnx {} {} assert_approx_equal (@var{actual}, @var{expected}, @var{tol}, @var{msg})
## Assert that two numeric arrays are equal within a specified tolerance.
##
## Throws an error with max discrepancy and shapes if condition fails.
##
## @table @asis
## @item @var{actual}
## Numeric matrix or vector to evaluate.
##
## @item @var{expected}
## Target reference numeric matrix or vector.
##
## @item @var{tol}
## Absolute tolerance scalar (default: 1e-6).
##
## @item @var{msg}
## Optional message describing the failure context.
## @end table
## @end deftypefn
function assert_approx_equal(actual, expected, tol, msg)
  if nargin < 3 || isempty(tol)
    tol = 1e-6;
  endif
  if nargin < 4 || isempty(msg)
    msg = "Values do not match within tolerance";
  endif

  if !isequal(size(actual), size(expected))
    error("%s: Dimension mismatch (actual [%s] vs expected [%s])", ...
          msg, mat2str(size(actual)), mat2str(size(expected)));
  endif

  diff = abs(double(actual(:)) - double(expected(:)));
  max_diff = max(diff);
  if isempty(max_diff)
    max_diff = 0;
  endif

  if max_diff > tol
    error("%s: Max difference %g exceeds tolerance %g", msg, max_diff, tol);
  endif
endfunction
