function run_scaling_1000()
  % RUN_SCALING_1000 Benchmark 1,000 medium-large SPN generation across worker counts.
  this_dir = fileparts(mfilename("fullpath"));
  repo_root = fileparts(this_dir);
  if !isempty(repo_root)
    addpath(repo_root);
    addpath(fullfile(repo_root, "src/petrinet"));
    addpath(fullfile(repo_root, "src/generation"));
    addpath(fullfile(repo_root, "src/analysis"));
    addpath(fullfile(repo_root, "src/augmentation"));
    addpath(fullfile(repo_root, "src/utils"));
    addpath(fullfile(repo_root, "src/report"));
  endif

  printf("===================================================================\n");
  printf("  SPN Generation Benchmark: 1,000 Medium-Large Nets\n");
  printf("===================================================================\n");
  printf("Configuration:\n");
  printf("  Num Places:          15\n");
  printf("  Num Transitions:     10\n");
  printf("  Num Samples:         1,000 (exact)\n");
  printf("  Marks Upper Limit:   1,000\n");
  printf("  Transformations:     Enabled (up to 5 per net)\n");
  printf("  Master Seed:         42\n");
  printf("  System Cores:        %d logical processors\n", nproc());
  printf("===================================================================\n\n");

  cfg = struct();
  cfg.generation_mode = "random";
  cfg.num_places = 15;
  cfg.num_transitions = 10;
  cfg.num_samples = 1000;
  cfg.exact_samples = true;
  cfg.seed = 42;
  cfg.place_upper_bound = 10;
  cfg.marks_lower_limit = 4;
  cfg.marks_upper_limit = 1000;
  cfg.min_firing_rate = 1;
  cfg.max_firing_rate = 10;
  cfg.enable_transformations = true;
  cfg.max_transforms_per_sample = 5;
  cfg.enable_statistics_report = false;
  cfg.quiet = true;

  test_workers = [1, 2, 4, 8, nproc()];
  num_runs = length(test_workers);

  results = struct();
  t_baseline = 0;

  printf("%-12s | %-12s | %-10s | %-16s | %-12s\n", ...
         "Workers", "Wall Time", "Speedup", "Throughput", "Sample Count");
  printf("-------------------------------------------------------------------\n");

  for i = 1:num_runs
    W = test_workers(i);
    out_file = fullfile(tempdir(), sprintf("bench_1000_w%d.jsonl", W));

    % Warm cache and run
    t0 = tic();
    [count, ~] = generate_parallel_dataset(cfg, W, out_file);
    elapsed = toc(t0);

    if W == 1
      t_baseline = elapsed;
      speedup = 1.0;
    else
      speedup = t_baseline / elapsed;
    endif

    throughput = count / elapsed;

    if W == nproc()
      worker_label = sprintf("%d (auto)", W);
    else
      worker_label = sprintf("%d", W);
    endif

    printf("%-12s | %8.3f s   | %7.2fx   | %8.1f nets/s  | %d\n", ...
           worker_label, elapsed, speedup, throughput, count);
    fflush(stdout);

    % Verify sample integrity
    assert(count == 1000, sprintf("Expected 1000 samples, got %d", count));

    % Clean up output file
    if exist(out_file, "file")
      delete(out_file);
    endif
  endfor

  printf("===================================================================\n");
endfunction
