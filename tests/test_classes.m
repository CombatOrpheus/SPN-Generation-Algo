function test_classes()
  % TEST_CLASSES Test suite for PetriNet and ReachabilityGraph classdef wrappers.
  printf("Running test_classes...\n");

  % 1. Test PetriNet constructor with dimensions
  P = 4;
  T = 3;
  pn = PetriNet(P, T);

  assert(pn.places == P, "Mismatch in places");
  assert(pn.transitions == T, "Mismatch in transitions");
  assert(all(size(pn.matrix) == [P, 2 * T + 1]), "Mismatch in matrix size");
  assert(all(size(pn.initial_marking) == [P, 1]), "Mismatch in initial marking size");
  assert(pn.total_tokens == 0, "Initial token count should be 0");
  assert(all(size(pn.pre_arcs) == [P, T]), "Mismatch in pre_arcs size");
  assert(all(size(pn.post_arcs) == [P, T]), "Mismatch in post_arcs size");
  assert(all(size(pn.incidence_matrix) == [P, T]), "Mismatch in incidence_matrix size");

  % 2. Test at() and set()
  pn = pn.set(1, 1, 2);
  assert(pn.at(1, 1) == 2, "at(1, 1) should return 2");
  assert(pn.pre_arcs(1, 1) == 2, "pre_arcs should reflect set(1, 1, 2)");

  pn = pn.set(2, T + 1, 3);
  assert(pn.at(2, T + 1) == 3, "at(2, T+1) should return 3");
  assert(pn.post_arcs(2, 1) == 3, "post_arcs should reflect set");
  assert(pn.incidence_matrix(2, 1) == 3, "incidence matrix should reflect post - pre");

  % Test column 2T+1 synchronizing with initial_marking
  pn = pn.set(1, 2 * T + 1, 5);
  assert(pn.initial_marking(1) == 5, "initial_marking(1) should synchronize with column 2T+1");
  assert(pn.total_tokens == 5, "total_tokens should update to 5");

  % 3. Test PetriNet struct conversion
  s = pn.to_struct();
  assert(isstruct(s), "to_struct() should return a struct");
  assert(s.places == P, "struct places mismatch");
  assert(s.transitions == T, "struct transitions mismatch");
  assert(all(s.matrix(:) == pn.matrix(:)), "struct matrix mismatch");
  assert(all(s.initial_marking == pn.initial_marking), "struct initial_marking mismatch");

  pn_copy = PetriNet(s);
  assert(pn_copy.places == pn.places, "Roundtrip struct places mismatch");
  assert(all(pn_copy.matrix(:) == pn.matrix(:)), "Roundtrip struct matrix mismatch");

  % 4. Test PetriNet.generate_random
  rand_pn = PetriNet.generate_random(5, 4);
  assert(rand_pn.places == 5, "Random net places mismatch");
  assert(rand_pn.transitions == 4, "Random net transitions mismatch");
  assert(rand_pn.total_tokens >= 1, "Random net should have tokens");
  pruned_rand = rand_pn.prune();
  assert(pruned_rand.is_connected(), "Pruned random net should be connected");

  % 5. Test prune()
  dense_pn = PetriNet(2, 2);
  dense_pn = dense_pn.set(1, 1, 1).set(1, 2, 1).set(1, 3, 1).set(1, 4, 1);
  dense_pn = dense_pn.set(2, 1, 1).set(2, 2, 1).set(2, 3, 1).set(2, 4, 1);
  initial_edges = sum(sum(dense_pn.matrix(:, 1:4)));
  pruned_pn = dense_pn.prune();
  final_edges = sum(sum(pruned_pn.matrix(:, 1:4)));
  assert(final_edges < initial_edges, "Prune should reduce excess edges");
  assert(pruned_pn.is_connected(), "Pruned net must remain connected");

  % 6. Test add_tokens_randomly()
  token_pn = PetriNet(10, 5);
  for trial = 1:5
    token_pn = token_pn.add_tokens_randomly();
    if token_pn.total_tokens > 0
      break;
    endif
  endfor
  assert(token_pn.total_tokens > 0, "add_tokens_randomly should add tokens");

  % 7. Test generate_reachability_graph()
  % Create simple 2-place producer-consumer net
  % P1 -> T1 -> P2, P2 -> T2 -> P1 with 1 token in P1
  wf_pn = PetriNet(2, 2);
  wf_pn = wf_pn.set(1, 1, 1);       % P1 to T1 (pre)
  wf_pn = wf_pn.set(2, 3, 1);       % T1 to P2 (post)
  wf_pn = wf_pn.set(2, 2, 1);       % P2 to T2 (pre)
  wf_pn = wf_pn.set(1, 4, 1);       % T2 to P1 (post)
  wf_pn = wf_pn.set(1, 5, 1);       % Initial token in P1

  rg = wf_pn.generate_reachability_graph(5, 50);
  assert(isa(rg, "ReachabilityGraph"), "Must return a ReachabilityGraph instance");
  assert(rg.num_vertices == 2, "Producer-consumer net must have 2 reachable states");
  assert(rg.num_edges == 2, "Producer-consumer net must have 2 transitions");
  assert(rg.is_bounded == true, "Net must be bounded");

  % 8. Test ReachabilityGraph methods
  adj = rg.to_adjacency_matrix();
  assert(all(size(adj) == [2, 2]), "Adjacency matrix size mismatch");
  assert(nnz(adj) == 2, "Adjacency matrix must have 2 non-zeros");

  lambda = [1.0; 2.0];
  [Q, tgt] = rg.compute_state_equation(lambda);
  assert(size(Q, 1) == 3 && size(Q, 2) == 2, "State matrix size mismatch");
  assert(length(tgt) == 3 && tgt(3) == 1.0, "Target vector mismatch");

  [pi, err] = rg.solve_steady_state(lambda);
  assert(!err, "solve_steady_state returned error");
  assert(abs(sum(pi) - 1.0) < 1e-6, "Steady-state probabilities must sum to 1");

  % Verify analytical solution for 2-state CTMC:
  % pi(1) * lambda(1) = pi(2) * lambda(2) => pi(1)*1 = pi(2)*2 => pi(1) = 2/3, pi(2) = 1/3
  assert(abs(pi(1) - 2/3) < 1e-4, "pi(1) mismatch with analytical solution");
  assert(abs(pi(2) - 1/3) < 1e-4, "pi(2) mismatch with analytical solution");

  % Test compute_average_markings()
  [avg_m, densities] = rg.compute_average_markings(pi);
  assert(length(avg_m) == 2, "Average markings must have length P");
  assert(abs(avg_m(1) - 2/3) < 1e-4, "Average marking P1 mismatch");
  assert(abs(avg_m(2) - 1/3) < 1e-4, "Average marking P2 mismatch");
  assert(length(densities) == 2, "Densities cell array must have length P");

  % Test polymorphic solve_steady_state passing ReachabilityGraph directly
  [pi_poly, err_poly] = solve_steady_state(rg, lambda);
  assert(!err_poly, "Polymorphic solve_steady_state returned error");
  assert(max(abs(pi - pi_poly)) < 1e-12, "Polymorphic solve_steady_state mismatch");

  % Test ReachabilityGraph struct conversion
  rg_struct = rg.to_struct();
  assert(isstruct(rg_struct), "rg.to_struct() should return struct");
  assert(rg_struct.num_vertices == rg.num_vertices, "rg struct num_vertices mismatch");
  rg_copy = ReachabilityGraph(rg_struct);
  assert(rg_copy.num_vertices == rg.num_vertices, "Roundtrip rg num_vertices mismatch");

  % 9. Test disp() outputs (ensure no syntax or evaluation errors)
  evalc("disp(wf_pn)");
  evalc("disp(rg)");

  printf("test_classes PASSED\n");
endfunction
