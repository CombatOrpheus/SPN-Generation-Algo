function pn = petrinet_new(num_places, num_transitions)
  % PETRINET_NEW Create a new Petri net structure.
  %
  % Syntax:
  %   pn = petrinet_new(num_places, num_transitions)
  %
  % Inputs:
  %   num_places      - Integer, number of places (P)
  %   num_transitions - Integer, number of transitions (T)
  %
  % Outputs:
  %   pn - Struct representing the Petri net with fields:
  %     places          - Number of places
  %     transitions     - Number of transitions
  %     matrix          - P x (2*T + 1) matrix:
  %                       columns 1:T        -> Pre (input arcs from places to transitions)
  %                       columns T+1:2*T    -> Post (output arcs from transitions to places)
  %                       column 2*T+1       -> Initial marking (M0)
  %     initial_marking - Column vector of length P with token count per place

  if nargin < 2
    error("petrinet_new requires num_places and num_transitions");
  endif

  pn = struct();
  pn.places = int32(num_places);
  pn.transitions = int32(num_transitions);
  pn.matrix = zeros(num_places, 2 * num_transitions + 1, "int32");
  pn.initial_marking = zeros(num_places, 1, "int32");
endfunction
