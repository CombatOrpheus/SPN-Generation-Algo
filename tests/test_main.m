function test_main()
  % TEST_MAIN Integration test suite for main entry point and CLI functionality.
  addpath(".");
  printf("Running test_main...\n");

  test_dir = fullfile(tempdir(), "test_spn_main");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  config_path = fullfile(test_dir, "test_config.json");
  out_path = fullfile(test_dir, "out.jsonl");

  % Base small test configuration
  cfg = struct();
  cfg.generation_mode = "random";
  cfg.num_places = 4;
  cfg.num_transitions = 2;
  cfg.num_samples = 5;
  cfg.exact_samples = true;
  cfg.seed = 123;
  cfg.output_file = out_path;
  cfg.place_upper_bound = 10;
  cfg.marks_lower_limit = 2;
  cfg.marks_upper_limit = 100;
  cfg.min_firing_rate = 1;
  cfg.max_firing_rate = 5;
  cfg.enable_transformations = false;
  cfg.enable_statistics_report = true;
  save_json(config_path, cfg);

  % 1. Test standard execution with exact samples
  main("--config", config_path);

  assert(exist(out_path, "file") == 2, "Output dataset should exist");
  items = load_jsonl(out_path);
  assert(length(items) == 5, sprintf("Expected exactly 5 samples, got %d", length(items)));
  assert(exist([out_path, ".html"], "file") == 2, "HTML report should exist");

  % 2. Test RNG reproducibility
  out_seed1 = fullfile(test_dir, "seed1.jsonl");
  out_seed2 = fullfile(test_dir, "seed2.jsonl");
  out_seed3 = fullfile(test_dir, "seed3.jsonl");

  main("--config", config_path, "--seed", "999", "--samples", "3", "--output", out_seed1);
  main("--config", config_path, "--seed", "999", "--samples", "3", "--output", out_seed2);
  main("--config", config_path, "--seed", "111", "--samples", "3", "--output", out_seed3);

  fid1 = fopen(out_seed1, "r"); s1 = fread(fid1, "*char")'; fclose(fid1);
  fid2 = fopen(out_seed2, "r"); s2 = fread(fid2, "*char")'; fclose(fid2);
  fid3 = fopen(out_seed3, "r"); s3 = fread(fid3, "*char")'; fclose(fid3);

  assert(strcmp(s1, s2), "Identical seeds must produce bit-for-bit identical JSONL datasets");
  assert(!strcmp(s1, s3), "Different seeds should produce different datasets");

  % 3. Test CLI usage output
  main("--help");

  % Cleanup
  if exist(test_dir, "dir")
    rmdir(test_dir, "s");
  endif

  printf("test_main PASSED\n");
endfunction
