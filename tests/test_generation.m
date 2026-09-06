function test_generation()
  % TEST_GENERATION Test suite for generation module.
  printf("Running test_generation...\n");

  % 1. Test hash_marking_64
  m1 = [1, 2, 3];
  m2 = [1, 2, 3];
  m3 = [3, 2, 1];
  m4 = [1, 2, 4];

  h1 = hash_marking_64(m1);
  h2 = hash_marking_64(m2);
  h3 = hash_marking_64(m3);
  h4 = hash_marking_64(m4);

  assert(strcmp(h1, h2), "Identical markings should produce same hash");
  assert(!strcmp(h1, h3), "Permuted markings should produce different hashes");
  assert(!strcmp(h1, h4), "Different markings should produce different hashes");

  % 2. Test Reachability Graph with both pure Octave and C++ oct extension
  for force_pure = [false, true]
    mode_str = "C++ oct extension";
    if force_pure
      mode_str = "pure Octave fallback";
    endif

    % Simple net: P1 -> T1 -> P2, M0 = [1; 0]
    pn = petrinet_new(2, 1);
    pn.matrix = int32([
      1, 0, 1;
      0, 1, 0
    ]);
    pn.initial_marking = int32([1; 0]);

    rg = generate_reachability_graph(pn, 10, 100, force_pure);

    assert(rg.is_bounded, sprintf("[%s] Graph should be bounded", mode_str));
    assert(rg.num_vertices == 2, sprintf("[%s] Expected 2 vertices, got %d", mode_str, rg.num_vertices));
    assert(rg.num_edges == 1, sprintf("[%s] Expected 1 edge, got %d", mode_str, rg.num_edges));
    assert(all(rg.edges(1, :) == [1, 2]), sprintf("[%s] Expected edge [1, 2]", mode_str));
    assert(rg.arc_transitions(1) == 1, sprintf("[%s] Expected arc transition 1", mode_str));

    % Cycle: P1 -> T1 -> P2 -> T2 -> P1, M0 = [1; 0]
    pn_cycle = petrinet_new(2, 2);
    pn_cycle.matrix(1, 1) = 1;
    pn_cycle.matrix(2, 3) = 1;
    pn_cycle.matrix(2, 2) = 1;
    pn_cycle.matrix(1, 4) = 1;
    pn_cycle.initial_marking = int32([1; 0]);

    rg_cycle = generate_reachability_graph(pn_cycle, 5, 50, force_pure);

    assert(rg_cycle.is_bounded, sprintf("[%s] Cycle graph should be bounded", mode_str));
    assert(rg_cycle.num_vertices == 2, sprintf("[%s] Expected 2 vertices in cycle, got %d", mode_str, rg_cycle.num_vertices));
    assert(rg_cycle.num_edges == 2, sprintf("[%s] Expected 2 edges in cycle, got %d", mode_str, rg_cycle.num_edges));

    % 3. Unbounded net: T1 consumes 1 token from P1 and produces 2 tokens in P1
    pn_unbounded = petrinet_new(1, 1);
    pn_unbounded.matrix = int32([1, 2, 1]); % Pre=1, Post=2, M0=1
    pn_unbounded.initial_marking = int32([1]);

    rg_unbounded = generate_reachability_graph(pn_unbounded, 5, 100, force_pure);
    assert(!rg_unbounded.is_bounded, sprintf("[%s] Token multiplying net should be marked unbounded", mode_str));

    % 4. Max markings limit exhaustion
    % P1 with 10 tokens, T1 consumes 1 token from P1 and produces 1 token in P2 (11 reachable states)
    pn_chain = petrinet_new(2, 1);
    pn_chain.matrix = int32([1, 0, 10; 0, 1, 0]);
    pn_chain.initial_marking = int32([10; 0]);

    % Limit max markings to 5 (less than 11 reachable states)
    rg_limited = generate_reachability_graph(pn_chain, 20, 5, force_pure);
    assert(!rg_limited.is_bounded, sprintf("[%s] Exceeding max markings limit must flag as unbounded", mode_str));

    % 5. Deadlock / 0 enabled transitions
    pn_deadlock = petrinet_new(2, 1);
    pn_deadlock.matrix = int32([1, 0, 0; 0, 1, 0]);
    pn_deadlock.initial_marking = int32([0; 0]); % 0 tokens, T1 cannot fire

    rg_deadlock = generate_reachability_graph(pn_deadlock, 10, 100, force_pure);
    assert(rg_deadlock.is_bounded, sprintf("[%s] Deadlock net should be bounded", mode_str));
    assert(rg_deadlock.num_vertices == 1, sprintf("[%s] Deadlock net should have 1 vertex", mode_str));
    assert(rg_deadlock.num_edges == 0, sprintf("[%s] Deadlock net should have 0 edges", mode_str));

    % 6. Self-loop transition (P1 -> T1 -> P1)
    pn_self = petrinet_new(1, 1);
    pn_self.matrix = int32([1, 1, 1]); % Pre=1, Post=1, M0=1
    pn_self.initial_marking = int32([1]);

    rg_self = generate_reachability_graph(pn_self, 10, 100, force_pure);
    assert(rg_self.is_bounded, sprintf("[%s] Self-loop net should be bounded", mode_str));
    assert(rg_self.num_vertices == 1, sprintf("[%s] Self-loop should have 1 vertex", mode_str));
    assert(rg_self.num_edges == 1, sprintf("[%s] Self-loop should have 1 edge", mode_str));
    assert(rg_self.edges(1, 1) == 1 && rg_self.edges(1, 2) == 1, sprintf("[%s] Self-loop edge should be [1, 1]", mode_str));
  endfor

  printf("test_generation PASSED\n");
endfunction
