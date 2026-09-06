function test_analysis()
  % TEST_ANALYSIS Test suite for analysis module.
  printf("Running test_analysis...\n");

  rg = struct();
  rg.vertices = int32([
    1, 0;
    0, 1
  ]);
  rg.edges = int32([1, 2]);
  rg.arc_transitions = int32([1]);
  rg.num_vertices = 2;
  rg.num_edges = 1;
  rg.is_bounded = true;

  lambda_values = [1.0];

  % 1. Test compute_state_equation
  [state_matrix, target_vector] = compute_state_equation(rg, lambda_values);

  expected_state_matrix = [
    -1.0, 0.0;
     1.0, 0.0;
     1.0, 1.0
  ];
  expected_target_vector = [0.0; 0.0; 1.0];

  assert(max(abs(state_matrix(:) - expected_state_matrix(:))) < 1e-9, "State matrix mismatch");
  assert(max(abs(target_vector(:) - expected_target_vector(:))) < 1e-9, "Target vector mismatch");

  % 2. Test solve_steady_state
  [probs, err] = solve_steady_state(state_matrix, target_vector);
  assert(!err, "Solving steady state should not return error");

  expected_probs = [0.0; 1.0];
  assert(max(abs(probs - expected_probs)) < 1e-9, "Steady state probs mismatch");

  % 3. Test compute_average_markings
  [avg_markings, densities] = compute_average_markings(rg, probs);

  expected_avg_markings = [0.0; 1.0];
  assert(max(abs(avg_markings - expected_avg_markings)) < 1e-9, "Average markings mismatch");

  assert(length(densities) == 2, "Expected 2 place densities");
  % Place 1: 100% prob of 0 tokens, 0% of 1 token
  assert(max(abs(densities{1} - [1.0, 0.0])) < 1e-9, "Place 1 densities mismatch");
  % Place 2: 0% prob of 0 tokens, 100% of 1 token
  assert(max(abs(densities{2} - [0.0, 1.0])) < 1e-9, "Place 2 densities mismatch");

  % 4. Test solve_steady_state_iterative and polymorphic solve_steady_state(rg, lambdas)
  rg_cycle = struct();
  rg_cycle.vertices = int32([1, 0; 0, 1]);
  rg_cycle.edges = int32([1, 2; 2, 1]);
  rg_cycle.arc_transitions = int32([1; 2]);
  rg_cycle.num_vertices = 2;
  rg_cycle.num_edges = 2;
  rg_cycle.is_bounded = true;

  % Transition 1 (1->2) rate = 2.0; Transition 2 (2->1) rate = 3.0
  % Stationary distribution: pi(1)*2 = pi(2)*3 => pi = [3/5, 2/5] = [0.6, 0.4]
  cycle_lambdas = [2.0; 3.0];
  [iter_probs, iter_err] = solve_steady_state_iterative(rg_cycle, cycle_lambdas);
  assert(!iter_err, "Iterative steady state solver should converge on cyclic CTMC");
  assert(max(abs(iter_probs - [0.6; 0.4])) < 1e-6, "Iterative steady state probabilities mismatch");

  % Test solve_steady_state polymorphic dispatch
  [poly_probs, poly_err] = solve_steady_state(rg_cycle, cycle_lambdas);
  assert(!poly_err, "Polymorphic solve_steady_state should succeed");
  assert(max(abs(poly_probs - [0.6; 0.4])) < 1e-6, "Polymorphic steady state probabilities mismatch");

  % 5. Test 3-State Asymmetric Cyclic CTMC with exact analytical stationary distribution
  % S1 -(1)-> S2 -(2)-> S3 -(3)-> S1
  % Analytical solution: pi = [6/11, 3/11, 2/11]
  rg_cycle3 = struct();
  rg_cycle3.vertices = int32([1, 0, 0; 0, 1, 0; 0, 0, 1]);
  rg_cycle3.edges = int32([1, 2; 2, 3; 3, 1]);
  rg_cycle3.arc_transitions = int32([1; 2; 3]);
  rg_cycle3.num_vertices = 3;
  rg_cycle3.num_edges = 3;
  rg_cycle3.is_bounded = true;

  lambdas3 = [1.0; 2.0; 3.0];
  expected_pi3 = [6.0/11.0; 3.0/11.0; 2.0/11.0];

  [probs3_iter, err3_iter] = solve_steady_state_iterative(rg_cycle3, lambdas3);
  assert(!err3_iter, "Iterative solver failed on 3-state cycle");
  assert(max(abs(probs3_iter - expected_pi3)) < 1e-6, "3-state iterative stationary distribution mismatch");

  [probs3_direct, err3_direct] = solve_steady_state(rg_cycle3, lambdas3);
  assert(!err3_direct, "Direct solver failed on 3-state cycle");
  assert(max(abs(probs3_direct - expected_pi3)) < 1e-6, "3-state direct stationary distribution mismatch");

  % 6. Test Single-State Boundary Condition (V = 1)
  rg_single = struct();
  rg_single.vertices = int32([3, 2]);
  rg_single.edges = zeros(0, 2, "int32");
  rg_single.arc_transitions = zeros(0, 1, "int32");
  rg_single.num_vertices = 1;
  rg_single.num_edges = 0;
  rg_single.is_bounded = true;

  [single_probs, single_err] = solve_steady_state_iterative(rg_single, []);
  assert(!single_err, "Single state solver should succeed");
  assert(all(single_probs == [1.0]), "Single state probability must be 1.0");

  % 7. Test Empty State Boundary Condition (V = 0)
  rg_empty = struct();
  rg_empty.vertices = zeros(0, 2, "int32");
  rg_empty.edges = zeros(0, 2, "int32");
  rg_empty.arc_transitions = zeros(0, 1, "int32");
  rg_empty.num_vertices = 0;
  rg_empty.num_edges = 0;
  rg_empty.is_bounded = true;

  [empty_probs, empty_err] = solve_steady_state_iterative(rg_empty, []);
  assert(!empty_err, "Empty graph solver should succeed");
  assert(isempty(empty_probs), "Empty graph probability should be empty");

  [empty_avg, empty_dens] = compute_average_markings(rg_empty, []);
  assert(isempty(empty_avg) && isempty(empty_dens), "Empty graph average markings should be empty");

  % 8. Test Absorbing States (No outgoing transitions, exit rates all 0)
  rg_absorbing = struct();
  rg_absorbing.vertices = int32([1, 0; 0, 1]);
  rg_absorbing.edges = zeros(0, 2, "int32");
  rg_absorbing.arc_transitions = zeros(0, 1, "int32");
  rg_absorbing.num_vertices = 2;
  rg_absorbing.num_edges = 0;
  rg_absorbing.is_bounded = true;

  [abs_probs, abs_err] = solve_steady_state_iterative(rg_absorbing, []);
  assert(!abs_err, "Absorbing state CTMC solver should succeed");
  assert(all(abs(abs_probs - [0.5; 0.5]) < 1e-9), "Absorbing states should have uniform probability");

  printf("test_analysis PASSED\n");
endfunction
