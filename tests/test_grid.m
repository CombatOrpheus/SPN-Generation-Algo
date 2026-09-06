function test_grid()
  % TEST_GRID Test suite for grid partitioning and sampling.
  printf("Running test_grid...\n");

  test_dir = fullfile(tempdir(), "test_spn_grid");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  raw_file = fullfile(test_dir, "raw.jsonl");

  % Generate a couple of samples and write to raw.jsonl
  pn = petrinet_new(2, 1);
  pn.matrix = int32([1, 0, 1; 0, 1, 0]);
  pn.initial_marking = int32([1; 0]);
  rg = generate_reachability_graph(pn, 10, 100);

  write_sample_jsonl(raw_file, pn, rg, [1.0], [0.0; 1.0], [0.0; 1.0], {[1.0, 0.0], [0.0, 1.0]});

  % Partition into grid
  places_bounds = [5, 10];
  markings_bounds = [4, 8];
  partition_data_into_grid(test_dir, false, raw_file, places_bounds, markings_bounds);

  assert(exist(fullfile(test_dir, "config.json"), "file") == 2, "Grid config.json should exist");
  assert(exist(fullfile(test_dir, "p1", "m1", "data1.json"), "file") == 2, "Grid cell data1.json should exist");

  % Sample and transform
  transformed = sample_and_transform_data(test_dir, 1, 2, 1, 5);
  assert(length(transformed) == 2, sprintf("Expected 2 transformed samples, got %d", length(transformed)));

  % 2. Test data accumulation mode (accumulate_data = true)
  % Partition the same raw file again with accumulation = true
  partition_data_into_grid(test_dir, true, raw_file, places_bounds, markings_bounds);
  assert(exist(fullfile(test_dir, "p1", "m1", "data2.json"), "file") == 2, "Accumulated grid cell data2.json should exist");

  % Sample again with samples_per_grid = 2
  transformed_accum = sample_and_transform_data(test_dir, 2, 1, 1, 5);
  assert(length(transformed_accum) == 2, "Expected 2 sampled nets from accumulated grid cell");

  % 3. Test exact boundary thresholds
  % Net with places = 5 (on bound 5), markings = 8 (on bound 8)
  % lookup([5, 10], 5) + 1 = 2 (p2); lookup([4, 8], 8) + 1 = 3 (m3)
  raw_file2 = fullfile(test_dir, "raw2.jsonl");
  pn_bound = petrinet_new(5, 1);
  rg_bound = struct();
  rg_bound.vertices = zeros(8, 5, "int32");
  rg_bound.edges = zeros(0, 2, "int32");
  rg_bound.arc_transitions = zeros(0, 1, "int32");
  rg_bound.num_vertices = 8;
  rg_bound.num_edges = 0;
  rg_bound.is_bounded = true;

  write_sample_jsonl(raw_file2, pn_bound, rg_bound, [], [], [], {});
  partition_data_into_grid(test_dir, true, raw_file2, places_bounds, markings_bounds);
  assert(exist(fullfile(test_dir, "p2", "m3", "data1.json"), "file") == 2, "Boundary net must map to bin p2/m3");

  % Cleanup
  if exist(test_dir, "dir")
    rmdir(test_dir, "s");
  endif

  printf("test_grid PASSED\n");
endfunction
