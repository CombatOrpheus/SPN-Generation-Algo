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

  unwind_protect
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

  % Verify SVG presentation graphs exist in HTML
  assert(!isempty(strfind(content, "<svg")), "SVG graphs missing in HTML report");
  assert(!isempty(strfind(content, "Presentation Graphs & Distributions")), "Graphs section missing in HTML report");
  assert(!isempty(strfind(content, "Distribution Box-and-Whisker Summary")), "Boxplot summary missing in HTML report");

  % 4. Test format_stats_table
  table_str = format_stats_table(stats);
  assert(!isempty(strfind(table_str, "SPN Dataset Frequentist Statistics")), "Table title missing in formatted table");
  assert(!isempty(strfind(table_str, "Places (P)")), "Places row missing in table");
  assert(!isempty(strfind(table_str, "Transitions (T)")), "Transitions row missing in table");

  % 5. Test rich dataset with states, edges, and marking densities
  s3 = struct();
  s3.num_places = 3;
  s3.num_transitions = 2;
  s3.num_states = 10;
  s3.num_edges = 15;
  s3.average_markings = [1.0; 2.0; 0.5];
  s3.steady_state_probs = [0.1; 0.2; 0.3; 0.4];
  s3.marking_densities = {[0.5, 0.5], [0.2, 0.8], [0.8, 0.2]};

  s4 = struct();
  s4.num_places = 5;
  s4.num_transitions = 4;
  s4.num_states = 20;
  s4.num_edges = 35;
  s4.average_markings = [0.5; 1.5; 1.0; 0.5; 0.5];
  s4.steady_state_probs = [0.5; 0.5];
  s4.marking_densities = {[0.6, 0.4], [0.3, 0.7], [0.4, 0.6], [0.5, 0.5], [0.7, 0.3]};

  stats_rich = calculate_stats({s3, s4});
  assert(stats_rich.num_samples == 2, "Expected 2 samples");
  assert(stats_rich.states.mean == 15.0, "Expected mean states = 15.0");
  assert(stats_rich.states.min == 10.0, "Expected min states = 10.0");
  assert(stats_rich.states.max == 20.0, "Expected max states = 20.0");
  assert(stats_rich.edges.mean == 25.0, "Expected mean edges = 25.0");
  assert(abs(stats_rich.density.mean - 1.625) < 1e-4, "Expected mean density = 1.625");
  assert(stats_rich.total_tokens.mean == 3.75, "Expected mean total tokens = 3.75");
  assert(stats_rich.max_prob.max == 0.5, "Expected max prob = 0.5");

  % 6. Test analyze_dataset on a sample JSONL file
  jsonl_file = fullfile(test_dir, "test_dataset.jsonl");
  fid_j = fopen(jsonl_file, "w");
  pn = struct("matrix", [1 0 0 1 0; 0 1 1 0 0], "places", 2, "transitions", 2);
  rg = struct("vertices", [1 0; 0 1], "edges", [1 2; 2 1], "num_edges", 2, "num_vertices", 2, "arc_transitions", [1 2]);
  write_sample_jsonl(fid_j, pn, rg, [1; 2], [0.5; 0.5], [0.5; 0.5], {[0.5 0.5], [0.5 0.5]});
  fclose(fid_j);

  ds_stats = analyze_dataset(jsonl_file, true);
  assert(ds_stats.num_samples == 1, "Expected 1 sample from analyze_dataset");
  assert(ds_stats.places.mean == 2, "Expected 2 places from analyze_dataset");
  assert(ds_stats.states.mean == 2, "Expected 2 states from analyze_dataset");
  assert(exist([jsonl_file, ".html"], "file") == 2, "Report HTML file should exist after analyze_dataset");

  unwind_protect_cleanup
    if exist(test_dir, "dir")
      confirm_recursive_rmdir(false, "local");
      rmdir(test_dir, "s");
    endif
  end_unwind_protect

  printf("test_report PASSED\n");
endfunction
