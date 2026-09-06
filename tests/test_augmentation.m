function test_augmentation()
  % TEST_AUGMENTATION Test suite for augmentation module.
  printf("Running test_augmentation...\n");

  % 1. Test generate_lambda_variations
  pn = petrinet_new(2, 1);
  rg = struct();
  rg.vertices = int32([1, 0; 0, 1]);
  rg.edges = int32([1, 2]);
  rg.arc_transitions = int32([1]);
  rg.num_vertices = 2;
  rg.num_edges = 1;
  rg.is_bounded = true;

  num_vars = 5;
  [vars, lambdas] = generate_lambda_variations(pn, rg, num_vars, 1, 10);
  assert(length(vars) == num_vars, sprintf("Expected %d variations, got %d", num_vars, length(vars)));
  assert(length(lambdas) == num_vars, sprintf("Expected %d lambdas, got %d", num_vars, length(lambdas)));
  assert(length(vars{1}.marking_densities) == 2, "marking_densities should be length P cell array");

  % 2. Test generate_petrinet_variations
  pn5 = petrinet_new(5, 3);
  pn5.matrix(1, 1) = 1;
  pn5.matrix(2, 4) = 1;
  pn5.matrix(2, 2) = 1;
  pn5.matrix(3, 5) = 1;
  pn5.initial_marking = int32([2; 1; 0; 0; 0]);
  pn5.matrix(:, 7) = pn5.initial_marking;

  vars_pn = generate_petrinet_variations(pn5, 10, 1, 100, num_vars, 1, 10);
  assert(length(vars_pn) > 0, "Expected at least one valid variation");
  assert(length(vars_pn{1}.marking_densities) == 5, "marking_densities in petri net variations should be length P cell array");

  % 3. Test token boundary clamping: places at 0 tokens cannot drop below 0
  pn_zero = petrinet_new(2, 1);
  pn_zero.matrix = int32([1, 0, 0; 0, 1, 0]); % M0 = [0; 0]
  pn_zero.initial_marking = int32([0; 0]);

  % Attempting to remove tokens should not create negative markings
  vars_zero = generate_petrinet_variations(pn_zero, 5, 0, 50, 10, 1, 5);
  for k = 1:length(vars_zero)
    assert(all(vars_zero{k}.petri_net.initial_marking >= 0), "Token count must never drop below 0");
    assert(all(vars_zero{k}.petri_net.initial_marking <= 5), "Token count must never exceed upper bound");
  endfor

  % 4. Test filtering of variations exceeding upper markings limit
  % If marks_upper_limit is 1, any variation with > 1 marking must be rejected
  vars_tight = generate_petrinet_variations(pn5, 10, 50, 60, 5, 1, 10);
  for k = 1:length(vars_tight)
    assert(vars_tight{k}.reachability_graph.num_vertices >= 50, "Generated variations must respect marks_lower_limit");
    assert(vars_tight{k}.reachability_graph.num_vertices <= 60, "Generated variations must respect marks_upper_limit");
  endfor

  printf("test_augmentation PASSED\n");
endfunction
