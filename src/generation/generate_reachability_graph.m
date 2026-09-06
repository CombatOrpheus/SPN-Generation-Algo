## -*- texinfo -*-
## @deftypefn {} {@var{rg} =} generate_reachability_graph (@var{pn}, @var{place_upper_limit}, @var{max_markings_to_explore})
## @deftypefnx {} {@var{rg} =} generate_reachability_graph (@var{pn}, @var{place_upper_limit}, @var{max_markings_to_explore}, @var{force_pure_octave})
## Generate reachability graph of a Petri net using BFS state-space exploration.
##
## Traverses the marking graph starting from @code{pn.initial_marking}. When compiled,
## uses the C++ extension @file{generate_reachability_graph_oct} with Robin Hood
## hash tables for high throughput.
##
## @table @asis
## @item @var{pn}
## Petri net struct created by @code{petrinet_new}.
##
## @item @var{place_upper_limit}
## Positive integer token threshold. If any place exceeds this capacity in an explored
## marking, the net is considered unbounded and exploration aborts.
##
## @item @var{max_markings_to_explore}
## Positive integer upper limit on discovered markings before marking graph is flagged
## as unbounded/exceeded.
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, bypasses compiled oct-file.
## @end table
##
## Returns struct @var{rg} containing:
## @table @asis
## @item @code{vertices}
## @math{V \times P} matrix of reachable markings.
## @item @code{edges}
## @math{E \times 2} matrix of 1-based source and destination vertex indices.
## @item @code{arc_transitions}
## @math{E \times 1} vector of 1-based firing transition indices.
## @item @code{num_vertices}
## Number of explored reachable markings @math{V}.
## @item @code{num_edges}
## Number of state transitions @math{E}.
## @item @code{is_bounded}
## Boolean flag indicating whether the state space is bounded within the limits.
## @end table
##
## @seealso{petrinet_new, hash_marking_64, generate_parallel_dataset}
## @end deftypefn
function rg = generate_reachability_graph(pn, place_upper_limit, max_markings_to_explore, force_pure_octave)
  if nargin < 4
    force_pure_octave = false;
  endif

  P = int32(pn.places);
  T = int32(pn.transitions);
  place_limit = int32(place_upper_limit);
  max_marks = int32(max_markings_to_explore);
  init_m = int32(pn.initial_marking(:));
  mat = int32(pn.matrix);

  % If C++ oct extension is available, use it for optimal speed
  if !force_pure_octave && exist("generate_reachability_graph_oct", "file") == 3
    rg = generate_reachability_graph_oct(mat, P, T, init_m, place_limit, max_marks);
    return;
  endif

  % Pure Octave fallback implementation
  Pre = mat(:, 1:T);
  Post = mat(:, (T + 1):(2 * T));
  Delta = Post - Pre;

  % Extract non-zero requirements for efficiency
  pre_places = cell(T, 1);
  pre_tokens = cell(T, 1);
  delta_places = cell(T, 1);
  delta_vals = cell(T, 1);

  for t = 1:T
    req_idx = find(Pre(:, t) > 0);
    pre_places{t} = req_idx;
    pre_tokens{t} = Pre(req_idx, t);

    chg_idx = find(Delta(:, t) ~= 0);
    delta_places{t} = chg_idx;
    delta_vals{t} = Delta(chg_idx, t);
  endfor

  % Preallocate buffers with capacity to avoid dynamic expansion
  cap_v = min(max_marks, int32(512));
  vertices = zeros(cap_v, P, "int32");
  vertices(1, :) = init_m';
  num_vertices = 1;

  cap_e = cap_v * 4;
  edges = zeros(cap_e, 2, "int32");
  arc_transitions = zeros(cap_e, 1, "int32");
  num_edges = 0;

  is_bounded = true;

  % Fast state lookup using string keys
  visited = struct();
  init_key = ["m_", sprintf("%d_", init_m)];
  visited.(init_key) = 1;

  % Preallocated queue buffer with head/tail pointers
  queue = zeros(max_marks, 1, "int32");
  queue(1) = 1;
  head = 1;
  tail = 1;

  while head <= tail
    curr_idx = queue(head);
    head = head + 1;

    curr_m = vertices(curr_idx, :)';

    if num_vertices >= max_marks
      is_bounded = false;
      break;
    endif

    for t = 1:T
      req_p = pre_places{t};
      if any(curr_m(req_p) < pre_tokens{t})
        continue;
      endif

      % Transition is enabled, fire it
      next_m = curr_m;
      chg_p = delta_places{t};
      next_m(chg_p) = next_m(chg_p) + delta_vals{t};

      if any(next_m > place_limit)
        is_bounded = false;
        break;
      endif

      key = ["m_", sprintf("%d_", next_m)];
      if isfield(visited, key)
        target_idx = visited.(key);
      else
        num_vertices = num_vertices + 1;
        if num_vertices > size(vertices, 1)
          vertices = [vertices; zeros(size(vertices, 1), P, "int32")];
        endif
        vertices(num_vertices, :) = next_m';
        visited.(key) = num_vertices;
        target_idx = num_vertices;

        tail = tail + 1;
        queue(tail) = num_vertices;
      endif

      num_edges = num_edges + 1;
      if num_edges > size(edges, 1)
        edges = [edges; zeros(size(edges, 1), 2, "int32")];
        arc_transitions = [arc_transitions; zeros(size(arc_transitions, 1), 1, "int32")];
      endif
      edges(num_edges, :) = [curr_idx, target_idx];
      arc_transitions(num_edges) = t;
    endfor

    if !is_bounded
      break;
    endif
  endwhile

  rg = struct();
  rg.vertices = vertices(1:num_vertices, :);
  rg.edges = edges(1:num_edges, :);
  rg.arc_transitions = arc_transitions(1:num_edges);
  rg.num_vertices = num_vertices;
  rg.num_edges = num_edges;
  rg.is_bounded = is_bounded;
endfunction
