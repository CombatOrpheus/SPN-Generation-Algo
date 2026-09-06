function test_petrinet()
  % TEST_PETRINET Test suite for petrinet module.
  printf("Running test_petrinet...\n");

  % 1. Test GenerateRandomPetriNet
  num_places = 5;
  num_transitions = 3;
  pn = petrinet_generate_random(num_places, num_transitions);

  assert(pn.places == num_places, "Mismatch in places");
  assert(pn.transitions == num_transitions, "Mismatch in transitions");
  assert(all(size(pn.matrix) == [num_places, 2 * num_transitions + 1]), "Mismatch in matrix size");
  assert(sum(pn.initial_marking) >= 1, "Initial marking should have tokens");
  assert(all(pn.initial_marking == pn.matrix(:, 2 * num_transitions + 1)), "Initial marking must match matrix column");

  % 2. Test Pruning excess edges
  pn2 = petrinet_new(2, 2);
  pn2.matrix = int32([
    1, 1, 1, 1, 0;
    1, 1, 1, 1, 0
  ]);
  initial_edges = sum(sum(pn2.matrix(:, 1:4)));
  pn2 = petrinet_prune(pn2);
  final_edges = sum(sum(pn2.matrix(:, 1:4)));
  assert(final_edges < initial_edges, "Prune should reduce excess edges");
  assert(petrinet_is_connected(pn2), "Pruned net must remain connected");

  % 3. Test Pruning missing connections
  pn3 = petrinet_new(2, 2);
  pn3 = petrinet_prune(pn3);
  for j = 1:4
    assert(sum(pn3.matrix(:, j)) > 0, sprintf("Column %d should have a connection", j));
  endfor

  % 4. Test AddTokensRandomly
  pn4 = petrinet_new(10, 5);
  % Run a few times if unlucky with 30% prob
  tokens = 0;
  for trial = 1:5
    pn4 = petrinet_add_tokens_randomly(pn4);
    tokens = sum(pn4.initial_marking);
    if tokens > 0
      break;
    endif
  endfor
  assert(tokens > 0, "AddTokensRandomly should have added tokens");

  % 5. Test True Bipartite Connectivity (degree >= 1 but 2 disconnected components)
  pn_disconn = petrinet_new(2, 2);
  % P1 <-> T1 (cols 1, 3)
  pn_disconn.matrix(1, 1) = 1;
  pn_disconn.matrix(1, 3) = 1;
  % P2 <-> T2 (cols 2, 4)
  pn_disconn.matrix(2, 2) = 1;
  pn_disconn.matrix(2, 4) = 1;
  % Both places have degree 2; both transitions have degree 2; BUT graph is disconnected into 2 components
  assert(!petrinet_is_connected(pn_disconn), "Two disjoint components must NOT be considered connected");

  % Connect P1 to T2 to bridge the components
  pn_conn = pn_disconn;
  pn_conn.matrix(1, 2) = 1;
  assert(petrinet_is_connected(pn_conn), "Bridged net must be considered connected");

  % 6. Test pruning preserves connectivity in both pure Octave and C++ modes
  for force_pure = [false, true]
    pn_dense = petrinet_new(4, 4);
    pn_dense.matrix(:, 1:8) = 1; % dense complete connections
    pn_dense = petrinet_prune(pn_dense, force_pure);
    assert(petrinet_is_connected(pn_dense), "Pruning must preserve connectivity");

    % 7. Pruning idempotency: already pruned net without excess edges remains stable
    % Net with exactly 1 input and 1 output per place and transition
    pn_stable = petrinet_new(2, 2);
    pn_stable.matrix = int32([1, 0, 0, 1, 0; 0, 1, 1, 0, 0]);
    pn_pruned1 = petrinet_prune(pn_stable, force_pure);
    assert(all(all(pn_pruned1.matrix == pn_stable.matrix)), "Stable net should not be modified by prune");
  endfor

  % 8. Test asymmetric Petri net shapes
  % P = 1, T = 6
  pn_1p = petrinet_generate_random(1, 6);
  assert(pn_1p.places == 1 && pn_1p.transitions == 6, "1-place net dimensions mismatch");
  pn_1p = petrinet_prune(pn_1p);
  assert(petrinet_is_connected(pn_1p), "1-place net after prune must be connected");

  % P = 6, T = 1
  pn_1t = petrinet_generate_random(6, 1);
  assert(pn_1t.places == 6 && pn_1t.transitions == 1, "1-transition net dimensions mismatch");
  pn_1t = petrinet_prune(pn_1t);
  assert(petrinet_is_connected(pn_1t), "1-transition net after prune must be connected");

  % 9. Test large random net generation and connectivity
  pn_large = petrinet_generate_random(25, 25);
  pn_large = petrinet_prune(pn_large);
  assert(petrinet_is_connected(pn_large), "Large net after pruning must be connected");

  printf("test_petrinet PASSED\n");
endfunction
