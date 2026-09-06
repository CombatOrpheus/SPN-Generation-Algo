## -*- texinfo -*-
## @deftypefn {} {@var{pn} =} PetriNet (@var{num_places}, @var{num_transitions})
## @deftypefnx {} {@var{pn} =} PetriNet (@var{pn_struct})
## Object-oriented representation of a Stochastic Petri Net (SPN).
##
## Encapsulates the Petri net topology, incidence matrix, and initial marking vector,
## maintaining architectural parity with @code{PetriNet} in @file{SPN-Algo-Go}.
##
## @table @asis
## @item @code{places}
## Number of places (@code{int32} scalar).
##
## @item @code{transitions}
## Number of transitions (@code{int32} scalar).
##
## @item @code{matrix}
## @code{int32} matrix of dimensions @math{P \times (2T + 1)}.
##
## @item @code{initial_marking}
## Column vector of length @math{P} representing token counts per place.
##
## @item @code{pre_arcs} (Dependent)
## @math{P \times T} input arc matrix.
##
## @item @code{post_arcs} (Dependent)
## @math{P \times T} output arc matrix.
##
## @item @code{incidence_matrix} (Dependent)
## Combined @math{P \times T} incidence matrix (@math{Post - Pre}).
##
## @item @code{total_tokens} (Dependent)
## Total number of initial tokens across all places.
## @end table
##
## @seealso{ReachabilityGraph, petrinet_new, petrinet_generate_random}
## @end deftypefn
classdef PetriNet
  properties (SetAccess = protected)
    places = int32(0);
    transitions = int32(0);
    matrix = int32([]);
    initial_marking = int32([]);
  endproperties

  properties (Dependent)
    pre_arcs
    post_arcs
    incidence_matrix
    total_tokens
  endproperties

  methods
    ## Constructor: initializes from dimensions or wraps an existing struct
    function obj = PetriNet(places_or_struct, transitions)
      if nargin == 0
        return;
      endif

      if isstruct(places_or_struct)
        s = places_or_struct;
        if !isfield(s, "places") || !isfield(s, "transitions") || ...
           !isfield(s, "matrix") || !isfield(s, "initial_marking")
          error("PetriNet: struct must contain 'places', 'transitions', 'matrix', and 'initial_marking'");
        endif
        obj.places = int32(s.places);
        obj.transitions = int32(s.transitions);
        obj.matrix = int32(s.matrix);
        obj.initial_marking = int32(s.initial_marking(:));
      else
        if nargin < 2
          error("PetriNet: requires (num_places, num_transitions) or a valid net struct");
        endif
        num_places = int32(places_or_struct);
        num_transitions = int32(transitions);
        if num_places < 0 || num_transitions < 0
          error("PetriNet: places and transitions must be non-negative");
        endif
        obj.places = num_places;
        obj.transitions = num_transitions;
        obj.matrix = zeros(num_places, 2 * num_transitions + 1, "int32");
        obj.initial_marking = zeros(num_places, 1, "int32");
      endif
    endfunction

    ## Dependent property getters
    function val = get.pre_arcs(obj)
      if obj.transitions == 0 || isempty(obj.matrix)
        val = zeros(obj.places, 0, "int32");
      else
        val = obj.matrix(:, 1:obj.transitions);
      endif
    endfunction

    function val = get.post_arcs(obj)
      if obj.transitions == 0 || isempty(obj.matrix)
        val = zeros(obj.places, 0, "int32");
      else
        val = obj.matrix(:, (obj.transitions + 1):(2 * obj.transitions));
      endif
    endfunction

    function val = get.incidence_matrix(obj)
      val = obj.post_arcs - obj.pre_arcs;
    endfunction

    function val = get.total_tokens(obj)
      val = sum(obj.initial_marking);
    endfunction

    ## Matrix element access (1-based, matching Go's At method)
    function val = at(obj, row, col)
      val = obj.matrix(row, col);
    endfunction

    ## Matrix element update (maintains copy-on-write value semantics)
    function obj = set(obj, row, col, val)
      obj.matrix(row, col) = int32(val);
      % Keep initial marking column synchronized
      if col == (2 * obj.transitions + 1)
        obj.initial_marking(row) = int32(val);
      endif
    endfunction

    ## Check bipartite connectivity
    function tf = is_connected(obj)
      tf = petrinet_is_connected(obj.to_struct());
    endfunction

    ## Structural pruning preserving connectivity
    function obj = prune(obj, force_pure_octave)
      if nargin < 2
        force_pure_octave = false;
      endif
      pruned_s = petrinet_prune(obj.to_struct(), force_pure_octave);
      obj = PetriNet(pruned_s);
    endfunction

    ## Randomly distribute tokens (adds 1 token per place with 30% probability)
    function obj = add_tokens_randomly(obj)
      marked_s = petrinet_add_tokens_randomly(obj.to_struct());
      obj = PetriNet(marked_s);
    endfunction

    ## Generate reachability graph via BFS state-space exploration
    function rg = generate_reachability_graph(obj, place_limit, max_marks, force_pure_octave)
      if nargin < 4
        force_pure_octave = false;
      endif
      rg_s = generate_reachability_graph(obj.to_struct(), place_limit, max_marks, force_pure_octave);
      rg = ReachabilityGraph(rg_s);
    endfunction

    ## Convert to raw plain struct for IPC, JSONL, or HDF5 streaming
    function s = to_struct(obj)
      s = struct();
      s.places = obj.places;
      s.transitions = obj.transitions;
      s.matrix = obj.matrix;
      s.initial_marking = obj.initial_marking;
    endfunction

    ## Human-readable REPL display
    function disp(obj)
      printf("<PetriNet: %d places, %d transitions, %d initial tokens>\n", ...
             obj.places, obj.transitions, obj.total_tokens);
    endfunction
  endmethods

  methods (Static)
    ## Generate a random connected Petri net
    function obj = generate_random(num_places, num_transitions)
      s = petrinet_generate_random(num_places, num_transitions);
      obj = PetriNet(s);
    endfunction

    ## Convenience factory from struct
    function obj = from_struct(s)
      obj = PetriNet(s);
    endfunction
  endmethods
endclassdef
