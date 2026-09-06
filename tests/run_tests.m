function run_tests()
  % RUN_TESTS Master test runner for SPN-Algo-Octave with structured reporting.
  this_dir = fileparts(mfilename("fullpath"));
  repo_root = fileparts(this_dir);
  if !isempty(repo_root)
    addpath(repo_root);
    addpath(fullfile(repo_root, "tests"));
  endif
  addpath(".");

  printf("===================================================================\n");
  printf("  SPN-Algo-Octave Test Suite (GNU Octave %s)\n", version());
  printf("===================================================================\n\n");

  suites = {
    {"test_petrinet", @test_petrinet},
    {"test_generation", @test_generation},
    {"test_analysis", @test_analysis},
    {"test_augmentation", @test_augmentation},
    {"test_grid", @test_grid},
    {"test_report", @test_report},
    {"test_utils", @test_utils},
    {"test_main", @test_main},
    {"test_parallel", @test_parallel}
  };

  num_suites = length(suites);
  results = cell(num_suites, 3); % name, status, duration
  failed_count = 0;
  t_total = tic();

  for i = 1:num_suites
    suite_name = suites{i}{1};
    suite_fn = suites{i}{2};

    t_start = tic();
    try
      suite_fn();
      duration = toc(t_start);
      results{i, 1} = suite_name;
      results{i, 2} = "PASS";
      results{i, 3} = duration;
    catch err
      duration = toc(t_start);
      results{i, 1} = suite_name;
      results{i, 2} = "FAIL";
      results{i, 3} = duration;
      failed_count = failed_count + 1;
      printf("\n[ERROR in %s]: %s\n", suite_name, err.message);
      if isfield(err, "stack") && !isempty(err.stack)
        for s = 1:length(err.stack)
          printf("    at %s (%s:%d)\n", err.stack(s).name, err.stack(s).file, err.stack(s).line);
        endfor
      endif
    end_try_catch
    printf("\n");
  endfor

  total_duration = toc(t_total);

  printf("===================================================================\n");
  printf("  Test Execution Summary\n");
  printf("===================================================================\n");
  printf("  %-25s %-10s %10s\n", "Suite Name", "Status", "Duration");
  printf("  -----------------------------------------------------------------\n");

  for i = 1:num_suites
    printf("  %-25s %-10s %9.3f s\n", results{i, 1}, results{i, 2}, results{i, 3});
  endfor

  printf("  -----------------------------------------------------------------\n");
  printf("  Total: %d | Passed: %d | Failed: %d | Elapsed: %.3f s\n", ...
         num_suites, num_suites - failed_count, failed_count, total_duration);
  printf("===================================================================\n");

  if failed_count > 0
    error("%d test suite(s) failed!", failed_count);
  endif
endfunction

if !isdeployed() && length(program_name()) > 0
  run_tests();
endif
