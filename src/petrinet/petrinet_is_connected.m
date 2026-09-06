## -*- texinfo -*-
## @deftypefn {} {@var{connected} =} petrinet_is_connected (@var{pn})
## Check if a Petri net structure is connected.
##
## A Petri net is considered connected if its underlying undirected bipartite graph
## is connected (all places and transitions belong to a single connected component)
## and there are no isolated nodes.
##
## Traversal is carried out via a fast breadth-first search (BFS) queue.
##
## @table @asis
## @item @var{pn}
## Petri net struct created by @code{petrinet_new}.
## @end table
##
## Returns boolean true if connected, false otherwise.
##
## @seealso{petrinet_new, petrinet_generate_random, petrinet_prune}
## @end deftypefn
function connected = petrinet_is_connected(pn)

  P = pn.places;
  T = pn.transitions;

  if P == 0 || T == 0
    connected = true;
    return;
  endif

  % Slicing arc columns
  arcs = pn.matrix(:, 1:(2 * T));

  % Quick check: ensure no isolated place or transition
  if !all(any(arcs, 2)) || !all(any(arcs, 1))
    connected = false;
    return;
  endif

  % Fast undirected bipartite BFS traversal matching Go's isConnected()
  % Logical adjacency between places (1:P) and transitions (1:T)
  adj = (arcs(:, 1:T) > 0) | (arcs(:, (T + 1):(2 * T)) > 0);

  visited_places = false(P, 1);
  visited_trans = false(T, 1);

  visited_places(1) = true;
  place_queue = zeros(P, 1, "int32");
  place_queue(1) = 1;
  p_head = 1;
  p_tail = 1;

  trans_queue = zeros(T, 1, "int32");
  t_head = 1;
  t_tail = 0;

  visited_places_count = 1;
  visited_trans_count = 0;

  while p_head <= p_tail || t_head <= t_tail
    if p_head <= p_tail
      p = place_queue(p_head);
      p_head = p_head + 1;

      % Find unvisited transitions connected to place p
      conn_t = find(adj(p, :)' & !visited_trans);
      for k = 1:length(conn_t)
        t = conn_t(k);
        visited_trans(t) = true;
        visited_trans_count = visited_trans_count + 1;
        t_tail = t_tail + 1;
        trans_queue(t_tail) = t;
      endfor
    endif

    if t_head <= t_tail
      t = trans_queue(t_head);
      t_head = t_head + 1;

      % Find unvisited places connected to transition t
      conn_p = find(adj(:, t) & !visited_places);
      for k = 1:length(conn_p)
        p = conn_p(k);
        visited_places(p) = true;
        visited_places_count = visited_places_count + 1;
        p_tail = p_tail + 1;
        place_queue(p_tail) = p;
      endfor
    endif
  endwhile

  connected = (visited_places_count == P) && (visited_trans_count == T);
endfunction


