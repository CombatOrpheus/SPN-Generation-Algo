## -*- texinfo -*-
## @deftypefn {} {@var{rg} =} ReachabilityGraph (@var{rg_struct})
## @deftypefnx {} {@var{rg} =} ReachabilityGraph (@var{vertices}, @var{edges}, @var{arc_transitions}, @var{is_bounded})
## Object-oriented representation of an SPN Reachability Graph.
##
## Encapsulates reachable marking states, directed state transitions, and
## continuous-time Markov chain analysis routines.
##
## @table @asis
## @item @code{vertices}
## @math{V \times P} matrix of reachable marking state vectors.
##
## @item @code{edges}
## @math{E \times 2} matrix of 1-based source and destination marking indices.
##
## @item @code{arc_transitions}
## Column vector of length @math{E} with 1-based firing transition indices.
##
## @item @code{num_vertices}
## Total number of reachable markings @math{V} (@code{int32} scalar).
##
## @item @code{num_edges}
## Total number of state transitions @math{E} (@code{int32} scalar).
##
## @item @code{is_bounded}
## Logical flag indicating whether the state-space exploration stayed within capacity bounds.
## @end table
##
## @seealso{PetriNet, generate_reachability_graph, solve_steady_state}
## @end deftypefn
classdef ReachabilityGraph
  properties (SetAccess = protected)
    vertices = int32([]);
    edges = int32([]);
    arc_transitions = int32([]);
    num_vertices = 0;
    num_edges = 0;
    is_bounded = true;
  endproperties

  methods
    ## Constructor
    function obj = ReachabilityGraph(arg1, edges, arc_transitions, is_bounded)
      if nargin == 0
        return;
      endif

      if isstruct(arg1)
        s = arg1;
        if !isfield(s, "vertices") || !isfield(s, "edges") || ...
           !isfield(s, "arc_transitions") || !isfield(s, "num_vertices") || ...
           !isfield(s, "num_edges") || !isfield(s, "is_bounded")
          error("ReachabilityGraph: struct missing required fields");
        endif
        obj.vertices = int32(s.vertices);
        obj.edges = int32(s.edges);
        obj.arc_transitions = int32(s.arc_transitions(:));
        obj.num_vertices = double(s.num_vertices);
        obj.num_edges = double(s.num_edges);
        obj.is_bounded = logical(s.is_bounded);
      else
        if nargin < 4
          error("ReachabilityGraph: requires (vertices, edges, arc_transitions, is_bounded) or struct");
        endif
        obj.vertices = int32(arg1);
        obj.edges = int32(edges);
        obj.arc_transitions = int32(arc_transitions(:));
        obj.num_vertices = double(size(obj.vertices, 1));
        obj.num_edges = double(size(obj.edges, 1));
        obj.is_bounded = logical(is_bounded);
      endif
    endfunction

    ## Convert to raw plain struct
    function s = to_struct(obj)
      s = struct();
      s.vertices = obj.vertices;
      s.edges = obj.edges;
      s.arc_transitions = obj.arc_transitions;
      s.num_vertices = obj.num_vertices;
      s.num_edges = obj.num_edges;
      s.is_bounded = obj.is_bounded;
    endfunction

    ## Return sparse adjacency matrix of the state transition graph
    function adj = to_adjacency_matrix(obj)
      if obj.num_vertices == 0 || obj.num_edges == 0
        adj = sparse(obj.num_vertices, obj.num_vertices);
      else
        src = double(obj.edges(:, 1));
        dest = double(obj.edges(:, 2));
        adj = sparse(src, dest, 1, double(obj.num_vertices), double(obj.num_vertices));
      endif
    endfunction

    ## Compute infinitesimal generator matrix system
    function [state_matrix, target_vector] = compute_state_equation(obj, lambda_values)
      [state_matrix, target_vector] = compute_state_equation(obj.to_struct(), lambda_values);
    endfunction

    ## Solve CTMC steady-state probability distribution
    function [probs, err] = solve_steady_state(obj, lambda_values)
      [probs, err] = solve_steady_state(obj.to_struct(), lambda_values);
    endfunction

    ## Compute expected place markings and token count distributions
    function [avg_markings, densities] = compute_average_markings(obj, steady_state_probs)
      [avg_markings, densities] = compute_average_markings(obj.to_struct(), steady_state_probs);
    endfunction

    ## Human-readable REPL display
    function disp(obj)
      if obj.is_bounded
        b_str = "true";
      else
        b_str = "false";
      endif
      printf("<ReachabilityGraph: %d markings, %d transitions, bounded=%s>\n", ...
             obj.num_vertices, obj.num_edges, b_str);
    endfunction
  endmethods

  methods (Static)
    ## Factory from struct
    function obj = from_struct(s)
      obj = ReachabilityGraph(s);
    endfunction
  endmethods
endclassdef
