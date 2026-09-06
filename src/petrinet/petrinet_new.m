## -*- texinfo -*-
## @deftypefn {} {@var{pn} =} petrinet_new (@var{num_places}, @var{num_transitions})
## Create a new Petri net structure.
##
## Create an empty Petri net data structure with @var{num_places} places and
## @var{num_transitions} transitions, initializing matrices to zeros.
##
## The returned struct @var{pn} contains the following fields:
## @table @asis
## @item @code{places}
## Number of places (@code{int32}).
##
## @item @code{transitions}
## Number of transitions (@code{int32}).
##
## @item @code{matrix}
## @code{int32} matrix of dimensions @var{num_places} x (2 * @var{num_transitions} + 1):
## @itemize @bullet
## @item Columns 1 to @var{T}: Pre-incidence matrix (input arcs from places to transitions).
## @item Columns @var{T}+1 to 2*@var{T}: Post-incidence matrix (output arcs from transitions to places).
## @item Column 2*@var{T}+1: Initial marking (@math{M_0}).
## @end itemize
##
## @item @code{initial_marking}
## Column vector of length @var{num_places} representing token counts per place.
## @end table
##
## @seealso{petrinet_generate_random, petrinet_is_connected, petrinet_prune}
## @end deftypefn
function pn = petrinet_new(num_places, num_transitions)
  if nargin < 2
    error("petrinet_new requires num_places and num_transitions");
  endif

  pn = struct();
  pn.places = int32(num_places);
  pn.transitions = int32(num_transitions);
  pn.matrix = zeros(num_places, 2 * num_transitions + 1, "int32");
  pn.initial_marking = zeros(num_places, 1, "int32");
endfunction
