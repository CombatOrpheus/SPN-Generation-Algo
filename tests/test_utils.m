function test_utils()
  % TEST_UTILS Test suite for JSON and JSONL utility functions.
  this_dir = fileparts(mfilename("fullpath"));
  repo_root = fileparts(this_dir);
  if !isempty(repo_root)
    addpath(repo_root);
  endif
  printf("Running test_utils...\n");

  test_dir = fullfile(tempdir(), "test_spn_utils");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  % 1. Test save_json and load_json roundtrip
  test_struct = struct();
  test_struct.name = "SPN_Test";
  test_struct.count = 42;
  test_struct.float_val = 3.14159;
  test_struct.is_active = true;
  test_struct.matrix = [1, 2, 3; 4, 5, 6];
  test_struct.nested = struct("level2", "value2");

  json_path = fullfile(test_dir, "test.json");
  save_json(json_path, test_struct);
  assert(exist(json_path, "file") == 2, "JSON file should exist");

  loaded = load_json(json_path);
  assert(strcmp(loaded.name, "SPN_Test"), "Loaded string mismatch");
  assert(loaded.count == 42, "Loaded integer mismatch");
  assert(abs(loaded.float_val - 3.14159) < 1e-5, "Loaded float mismatch");
  assert(loaded.is_active == true, "Loaded boolean mismatch");
  assert(all(all(loaded.matrix == test_struct.matrix)), "Loaded matrix mismatch");
  assert(strcmp(loaded.nested.level2, "value2"), "Loaded nested struct mismatch");

  % 2. Test write_sample_jsonl and load_jsonl
  jsonl_path = fullfile(test_dir, "test.jsonl");

  pn = petrinet_new(2, 1);
  pn.matrix = int32([1, 0, 1; 0, 1, 0]);
  pn.initial_marking = int32([1; 0]);

  rg = struct();
  rg.vertices = int32([1, 0; 0, 1]);
  rg.edges = int32([1, 2]); % 1-based in Octave
  rg.arc_transitions = int32([1]); % 1-based in Octave
  rg.num_vertices = 2;
  rg.num_edges = 1;
  rg.is_bounded = true;

  lambdas = [2.5];
  probs = [0.0; 1.0];
  avg_markings = [0.0; 1.0];
  densities = {[1.0, 0.0], [0.0, 1.0]};

  % Write sample using file path
  write_sample_jsonl(jsonl_path, pn, rg, lambdas, probs, avg_markings, densities);

  % Write second sample using open file descriptor
  fid = fopen(jsonl_path, "a");
  write_sample_jsonl(fid, pn, rg, [3.0], [0.5; 0.5], [0.5; 0.5], densities);
  fclose(fid);

  items = load_jsonl(jsonl_path);
  assert(length(items) == 2, sprintf("Expected 2 samples in JSONL, got %d", length(items)));

  % Verify 0-based conversion in JSON output matching Go specification
  item1 = items{1};
  assert(all(all(item1.petri_net == pn.matrix)), "petri_net matrix mismatch in JSONL");
  assert(all(all(item1.vertices == rg.vertices)), "vertices matrix mismatch in JSONL");

  % Check edge is 0-based: [0, 1]
  if iscell(item1.edges)
    edge1 = double(cell2mat(item1.edges));
  else
    edge1 = double(item1.edges);
  endif
  assert(all(edge1 == [0, 1]), "Edge in JSONL must be converted to 0-based index [0, 1]");

  % Check arc_transition is 0-based: 0
  if iscell(item1.arc_transitions)
    arc1 = double(cell2mat(item1.arc_transitions));
  else
    arc1 = double(item1.arc_transitions);
  endif
  assert(arc1 == 0, "Arc transition in JSONL must be converted to 0-based index");

  if iscell(item1.lambda_values)
    lv = double(cell2mat(item1.lambda_values));
  else
    lv = double(item1.lambda_values);
  endif
  assert(abs(lv(1) - 2.5) < 1e-9, "Lambda values mismatch");
  assert(abs(item1.steady_state_probs(2) - 1.0) < 1e-9, "Steady state probs mismatch");
  assert(abs(item1.average_markings(2) - 1.0) < 1e-9, "Average markings mismatch");
  assert(length(item1.marking_densities) == 2, "Marking densities should have length P");

  % 3. Error handling on missing files
  caught_json_err = false;
  try
    load_json(fullfile(test_dir, "nonexistent.json"));
  catch
    caught_json_err = true;
  end_try_catch
  assert(caught_json_err, "load_json should throw error on missing file");

  caught_jsonl_err = false;
  try
    load_jsonl(fullfile(test_dir, "nonexistent.jsonl"));
  catch
    caught_jsonl_err = true;
  end_try_catch
  assert(caught_jsonl_err, "load_jsonl should throw error on missing file");

  % Cleanup
  if exist(test_dir, "dir")
    rmdir(test_dir, "s");
  endif

  printf("test_utils PASSED\n");
endfunction
