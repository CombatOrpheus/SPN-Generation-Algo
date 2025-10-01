%% test_spn()
%%
%% A test script to verify the core functionality of the SPN generator and
%% analysis tools.
%%
%% This script serves as a "smoke test" for the toolkit. It runs through the
%% main public-facing functions, creating a random SPN and then processing it
%% through the analysis, filtering, and modification pipeline.
%%
%% The function uses assertions to check for execution errors and to verify
%% that the outputs of each function have the correct dimensions and basic
%% properties. It provides a quick way to ensure the integrity of the codebase
%% after changes have been made.
%%
%% To run this test, simply execute `test_spn` in the Octave command window.
%% The script will print the status of each test and will halt with an error
%% if any assertion fails.
%%
%% No inputs or outputs.

function test_spn()
  disp("--- Running SPN Toolbox Test Suite ---");

  % --- Test Parameters ---
  pn = 5; % Number of places
  tn = 4; % Number of transitions
  prob = 0.3; % Connection probability
  max_lambda = 10; % Max firing rate

  % --- 1. Test spn_generate_random ---
  disp("1. Testing spn_generate_random...");
  [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda);
  assert(all(size(cm) == [pn, 2*tn + 1]), "cm has incorrect dimensions");
  assert(all(size(lambda) == [tn, 1]), "lambda has incorrect dimensions");
  disp("   ... PASSED");

  % --- 2. Test get_reachability_graph ---
  disp("2. Testing get_reachability_graph...");
  reach_graph = get_reachability_graph(cm);
  assert(isstruct(reach_graph), "reach_graph should be a struct");
  assert(isfield(reach_graph, 'bounded'), "reach_graph is missing 'bounded' field");
  disp("   ... PASSED");

  % --- 3. Test filter_spn ---
  disp("3. Testing filter_spn...");
  % Note: filter_spn has random elements, so it might not always return a
  % 'valid' net. We test that it runs without error and returns a struct.
  filter_result = filter_spn(cm);
  assert(isstruct(filter_result), "filter_result should be a struct");
  assert(isfield(filter_result, 'valid'), "filter_result is missing 'valid' field");
  disp("   ... PASSED (execution only)");

  % --- 4. Test prune_petri ---
  disp("4. Testing prune_petri...");
  pruned_cm = prune_petri(cm);
  assert(all(size(pruned_cm) == size(cm)), "pruned_cm has incorrect dimensions");
  disp("   ... PASSED");

  % --- 5. Test add_token ---
  disp("5. Testing add_token...");
  % Test with default probability (0.2)
  cm_with_tokens_default = add_token(cm);
  assert(all(size(cm_with_tokens_default) == size(cm)), "add_token (default) returned incorrect dimensions");
  assert(sum(cm_with_tokens_default(:, end)) >= sum(cm(:, end)), "add_token (default) failed to add tokens");

  % Test with a custom probability (e.g., 0.5)
  cm_with_tokens_custom = add_token(cm, 0.5);
  assert(all(size(cm_with_tokens_custom) == size(cm)), "add_token (custom) returned incorrect dimensions");
  assert(sum(cm_with_tokens_custom(:, end)) >= sum(cm(:, end)), "add_token (custom) failed to add tokens");

  % Test with probability 1 (must add a token to every place)
  original_tokens = sum(cm(:, end));
  cm_with_all_tokens = add_token(cm, 1.0);
  expected_tokens = original_tokens + pn;
  assert(sum(cm_with_all_tokens(:, end)) == expected_tokens, "add_token (prob=1) failed to add a token to every place");
  disp("   ... PASSED");

  disp("--- All tests completed successfully! ---");
endfunction