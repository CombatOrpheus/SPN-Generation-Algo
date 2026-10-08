## -*- texinfo -*-
## @deftypefn {} {@var{s} =} create_synthetic_sample ()
## @deftypefnx {} {@var{s} =} create_synthetic_sample (@var{P}, @var{T})
## Generate a fully-populated synthetic SPN dataset record struct for unit tests.
##
## Constructs a valid, bounded sample containing petri_net, vertices, edges,
## arc_transitions, lambda_values, steady_state_probs, avg_markings, and marking_densities.
##
## Returns struct @var{s}.
##
## @seealso{create_test_petrinet, generate_reachability_graph, solve_steady_state}
## @end deftypefn
function s = create_synthetic_sample(P, T)
  if nargin < 2
    P = 2;
    T = 1;
  endif

  s = struct();
  if P == 2 && T == 1
    s.petri_net = int32([1, 0, 1; 0, 1, 0]);
    s.vertices = int32([1, 0; 0, 1]);
    s.edges = int32([1, 2]);
    s.arc_transitions = int32([1]);
    s.lambda_values = [2.0];
    s.steady_state_probs = [0.4; 0.6];
    s.average_markings = [0.4; 0.6];
    s.marking_densities = {[0.6, 0.4]; [0.4, 0.6]};
  else
    pn = create_test_petrinet(P, T);
    rg = generate_reachability_graph(pn, 10, 500);
    lambdas = double(ones(T, 1) * 2.0);
    [probs, ~] = solve_steady_state(rg, lambdas);
    [avg_m, dens] = compute_average_markings(rg, probs);

    s.petri_net = pn.matrix;
    s.vertices = rg.vertices;
    s.edges = rg.edges;
    s.arc_transitions = rg.arc_transitions;
    s.lambda_values = lambdas;
    s.steady_state_probs = probs;
    s.average_markings = avg_m;
    s.marking_densities = dens;
  endif
endfunction
