function test_report()
  % TEST_REPORT Test suite for report module (calculate_stats and generate_html_report).
  this_dir = fileparts(mfilename("fullpath"));
  repo_root = fileparts(this_dir);
  if !isempty(repo_root)
    addpath(repo_root);
  endif
  printf("Running test_report...\n");

  % 1. Test calculate_stats with empty input
  empty_stats = calculate_stats({});
  assert(empty_stats.num_samples == 0, "Empty stats num_samples should be 0");
  assert(empty_stats.avg_places == 0.0, "Empty stats avg_places should be 0");
  assert(empty_stats.avg_transitions == 0.0, "Empty stats avg_transitions should be 0");
  assert(empty_stats.avg_markings == 0.0, "Empty stats avg_markings should be 0");
  assert(empty_stats.avg_steady_state_probs == 0.0, "Empty stats avg_steady_state_probs should be 0");

  % 2. Test calculate_stats with multiple sample results
  s1 = struct();
  s1.num_places = 2;
  s1.num_transitions = 1;
  s1.average_markings = [0.5; 0.5];
  s1.steady_state_probs = [0.5; 0.5];

  s2 = struct();
  s2.num_places = 4;
  s2.num_transitions = 3;
  s2.average_markings = [0.2; 0.8; 1.0; 0.0];
  s2.steady_state_probs = [0.2; 0.8];

  stats = calculate_stats({s1, s2});
  assert(stats.num_samples == 2, "Expected 2 samples");
  assert(abs(stats.avg_places - 3.0) < 1e-9, "Expected avg_places = 3.0");
  assert(abs(stats.avg_transitions - 2.0) < 1e-9, "Expected avg_transitions = 2.0");
  % s1 sum = 1.0; s2 sum = 2.0; mean = 1.5
  assert(abs(stats.avg_markings - 1.5) < 1e-9, "Expected avg_markings = 1.5");
  assert(abs(stats.avg_steady_state_probs - 1.0) < 1e-9, "Expected avg_steady_state_probs = 1.0");

  % 3. Test generate_html_report
  test_dir = fullfile(tempdir(), "test_spn_report");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  html_file = fullfile(test_dir, "report.html");
  generate_html_report(html_file, stats);

  assert(exist(html_file, "file") == 2, "Report HTML file should exist");
  fid = fopen(html_file, "r");
  content = fread(fid, "*char")';
  fclose(fid);

  assert(!isempty(strfind(content, "<h1>SPN Dataset Statistics</h1>")), "HTML title heading missing");
  assert(!isempty(strfind(content, "<td>Number of samples</td>")), "Samples row missing");
  assert(!isempty(strfind(content, "<td>2</td>")), "Sample count value '2' missing in HTML table");
  assert(!isempty(strfind(content, "<td>3.00</td>")), "Avg places '3.00' missing in HTML table");
  assert(!isempty(strfind(content, "<td>2.00</td>")), "Avg transitions '2.00' missing in HTML table");
  assert(!isempty(strfind(content, "<td>1.50</td>")), "Avg markings '1.50' missing in HTML table");

  % Cleanup
  if exist(test_dir, "dir")
    rmdir(test_dir, "s");
  endif

  printf("test_report PASSED\n");
endfunction
