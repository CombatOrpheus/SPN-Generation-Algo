function test_parallel()
  % TEST_PARALLEL Unit and integration tests for parallel multiprocessing generation.
  printf("Running test_parallel...\n");

  test_dir = fullfile(tempdir(), "test_spn_parallel");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  base_cfg = struct();
  base_cfg.generation_mode = "random";
  base_cfg.num_places = 4;
  base_cfg.num_transitions = 2;
  base_cfg.num_samples = 6;
  base_cfg.exact_samples = true;
  base_cfg.seed = 456;
  base_cfg.place_upper_bound = 10;
  base_cfg.marks_lower_limit = 2;
  base_cfg.marks_upper_limit = 100;
  base_cfg.min_firing_rate = 1;
  base_cfg.max_firing_rate = 5;
  base_cfg.enable_transformations = false;
  base_cfg.enable_statistics_report = true;

  % 1. Test 2-worker generation
  out2 = fullfile(test_dir, "out_w2.jsonl");
  cfg2 = base_cfg;
  cfg2.num_samples = 6;
  [w2_count, w2_stats] = generate_parallel_dataset(cfg2, 2, out2);
  assert(w2_count == 6, sprintf("Expected 6 samples from 2 workers, got %d", w2_count));
  assert(exist(out2, "file") == 2, "Output file must exist");
  items2 = load_jsonl(out2);
  assert(length(items2) == 6, sprintf("Loaded items length should be 6, got %d", length(items2)));
  assert(exist([out2, ".html"], "file") == 2, "HTML report should exist");

  % 2. Test 4-worker generation with uneven partition (7 samples / 4 workers -> [2 2 2 1])
  out4 = fullfile(test_dir, "out_w4.jsonl");
  cfg4 = base_cfg;
  cfg4.num_samples = 7;
  [w4_count, w4_stats] = generate_parallel_dataset(cfg4, 4, out4);
  assert(w4_count == 7, sprintf("Expected 7 samples from 4 workers, got %d", w4_count));
  items4 = load_jsonl(out4);
  assert(length(items4) == 7, sprintf("Loaded items length should be 7, got %d", length(items4)));

  % 3. Test reproducibility with same seed and workers
  out_rep1 = fullfile(test_dir, "rep1.jsonl");
  out_rep2 = fullfile(test_dir, "rep2.jsonl");
  cfg_rep = base_cfg;
  cfg_rep.seed = 777;
  cfg_rep.num_samples = 4;
  generate_parallel_dataset(cfg_rep, 2, out_rep1);
  generate_parallel_dataset(cfg_rep, 2, out_rep2);

  fid1 = fopen(out_rep1, "r"); s1 = fread(fid1, "*char")'; fclose(fid1);
  fid2 = fopen(out_rep2, "r"); s2 = fread(fid2, "*char")'; fclose(fid2);
  assert(strcmp(s1, s2), "Parallel generation must be strictly reproducible with same seed and worker count");

  % 4. Boundary cases: N < W (more workers than samples)
  out_few = fullfile(test_dir, "out_few.jsonl");
  cfg_few = base_cfg;
  cfg_few.num_samples = 2;
  [cnt_few, ~] = generate_parallel_dataset(cfg_few, 8, out_few);
  assert(cnt_few == 2, sprintf("Expected 2 samples when N < W, got %d", cnt_few));

  % 5. Single-worker fallback (W=1)
  out_single = fullfile(test_dir, "out_single.jsonl");
  cfg_single = base_cfg;
  cfg_single.num_samples = 3;
  [cnt_single, ~] = generate_parallel_dataset(cfg_single, 1, out_single);
  assert(cnt_single == 3, sprintf("Expected 3 samples for W=1, got %d", cnt_single));

  % 6. N=0 samples edge case
  out_zero = fullfile(test_dir, "out_zero.jsonl");
  cfg_zero = base_cfg;
  cfg_zero.num_samples = 0;
  [cnt_zero, ~] = generate_parallel_dataset(cfg_zero, 4, out_zero);
  assert(cnt_zero == 0, sprintf("Expected 0 samples for N=0, got %d", cnt_zero));

  % Cleanup
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif

  printf("test_parallel PASSED\n");
endfunction
