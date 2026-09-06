% benchmark_hdf5.m - Comprehensive benchmark comparing HDF5 vs JSONL, C++ vs Octave, Flat vs Groups
%
% Usage:
%   octave benchmarks/benchmark_hdf5.m
%   ./dev.sh octave --eval "benchmark_hdf5"

function benchmark_hdf5(num_samples)
  if nargin < 1 || isempty(num_samples)
    num_samples = 100;
  endif

  % Add include paths
  addpath("src/petrinet");
  addpath("src/generation");
  addpath("src/analysis");
  addpath("src/augmentation");
  addpath("src/utils");
  if exist("build/oct", "dir")
    addpath("build/oct");
  endif

  printf("========================================================================================\n");
  printf("  HDF5 vs JSONL Storage & Runtime Efficiency Benchmark (GNU Octave %s)\n", version());
  printf("========================================================================================\n\n");

  test_dir = fullfile(tempdir(), "spn_hdf5_benchmarks");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  % 1. Generate representative synthetic SPN sample set
  printf("Generating %d realistic SPN benchmark samples (varying P, T, and state-spaces)...\n", num_samples);
  fflush(stdout);

  rand("seed", 42);
  samples = cell(num_samples, 1);
  gen_start = time();
  count = 0;
  total_states = 0;
  total_edges = 0;

  while count < num_samples
    P = randi([3, 7]);
    T = randi([2, 6]);
    pn = petrinet_generate_random(P, T);
    pn = petrinet_prune(pn);
    pn = petrinet_add_tokens_randomly(pn);
    rg = generate_reachability_graph(pn, 10, 2000);
    if rg.is_bounded && rg.num_vertices >= 3
      lambdas = double(randi([1, 10], pn.transitions, 1));
      [probs, err] = solve_steady_state(rg, lambdas);
      if !err
        avg_m = compute_average_markings(rg, probs);
        s = struct();
        s.petri_net = int32(pn.matrix);
        s.vertices = int32(rg.vertices);
        s.edges = int32(rg.edges);
        s.arc_transitions = int32(rg.arc_transitions);
        s.lambda_values = lambdas;
        s.steady_state_probs = probs;
        s.avg_markings = avg_m;
        count++;
        samples{count} = s;
        total_states += rg.num_vertices;
        total_edges += rg.num_edges;
      endif
    endif
  endwhile
  gen_time = time() - gen_start;
  printf("Dataset prepared in %.2f s: %d samples, avg places=%.1f, total states=%d, total edges=%d\n\n", ...
         gen_time, num_samples, mean(cellfun(@(x) size(x.petri_net, 1), samples)), total_states, total_edges);
  fflush(stdout);

  % Define benchmark configurations
  % Struct fields: name, engine ('jsonl', 'c++', 'octave'), layout ('flat', 'groups', 'jsonl'), comp_level, file_ext
  configs = {
    struct("name", "JSONL Baseline",    "engine", "jsonl",  "layout", "jsonl",  "level", 0, "file", "ds_baseline.jsonl");
    struct("name", "C++ Flat (z=0)",     "engine", "c++",    "layout", "flat",   "level", 0, "file", "ds_c_flat_z0.h5");
    struct("name", "C++ Flat (z=4)",     "engine", "c++",    "layout", "flat",   "level", 4, "file", "ds_c_flat_z4.h5");
    struct("name", "C++ Flat (z=6)",     "engine", "c++",    "layout", "flat",   "level", 6, "file", "ds_c_flat_z6.h5");
    struct("name", "C++ Flat (z=9)",     "engine", "c++",    "layout", "flat",   "level", 9, "file", "ds_c_flat_z9.h5");
    struct("name", "C++ Groups (z=0)",   "engine", "c++",    "layout", "groups", "level", 0, "file", "ds_c_grp_z0.h5");
    struct("name", "C++ Groups (z=4)",   "engine", "c++",    "layout", "groups", "level", 4, "file", "ds_c_grp_z4.h5");
    struct("name", "C++ Groups (z=6)",   "engine", "c++",    "layout", "groups", "level", 6, "file", "ds_c_grp_z6.h5");
    struct("name", "C++ Groups (z=9)",   "engine", "c++",    "layout", "groups", "level", 9, "file", "ds_c_grp_z9.h5");
    struct("name", "Octave Flat (z=0)",  "engine", "octave", "layout", "flat",   "level", 0, "file", "ds_p_flat_z0.h5");
    struct("name", "Octave Groups (z=0)","engine", "octave", "layout", "groups", "level", 0, "file", "ds_p_grp_z0.h5");
  };

  num_configs = length(configs);
  file_sizes = zeros(num_configs, 1);
  write_times = zeros(num_configs, 1);
  read_times = zeros(num_configs, 1);
  data_matches = true(num_configs, 1);

  % Number of measurement repetitions for stable timing
  num_reps = 3;

  for c = 1:num_configs
    cfg = configs{c};
    fpath = fullfile(test_dir, cfg.file);

    % Warmup / initial run
    if strcmp(cfg.engine, "jsonl")
      write_jsonl_dataset(samples, fpath);
    elseif strcmp(cfg.engine, "c++")
      export_dataset_hdf5(samples, fpath, cfg.layout, cfg.level, false);
    else % octave
      export_dataset_hdf5(samples, fpath, cfg.layout, cfg.level, true);
    endif

    % Measure file size
    finfo = stat(fpath);
    file_sizes(c) = finfo.size;

    % Measure Write time over repetitions
    w_start = time();
    for r = 1:num_reps
      if strcmp(cfg.engine, "jsonl")
        write_jsonl_dataset(samples, fpath);
      elseif strcmp(cfg.engine, "c++")
        export_dataset_hdf5(samples, fpath, cfg.layout, cfg.level, false);
      else
        export_dataset_hdf5(samples, fpath, cfg.layout, cfg.level, true);
      endif
    endfor
    write_times(c) = (time() - w_start) / num_reps;

    % Measure Read time over repetitions and verify integrity
    loaded_data = [];
    r_start = time();
    for r = 1:num_reps
      if strcmp(cfg.engine, "jsonl")
        loaded_data = load_jsonl(fpath);
      elseif strcmp(cfg.engine, "c++")
        loaded_data = load_dataset_hdf5(fpath, false);
      else
        loaded_data = load_dataset_hdf5(fpath, true);
      endif
    endfor
    read_times(c) = (time() - r_start) / num_reps;

    % Verify integrity
    if length(loaded_data) != num_samples
      data_matches(c) = false;
    else
      % Check first, middle, and last samples
      test_indices = unique([1, round(num_samples/2), num_samples]);
      for idx = test_indices
        s_orig = samples{idx};
        s_load = loaded_data{idx};
        if !isequal(int32(s_orig.petri_net), int32(s_load.petri_net)) || ...
           !isequal(int32(s_orig.vertices), int32(s_load.vertices)) || ...
           !isequal(int32(s_orig.edges), int32(s_load.edges))
          data_matches(c) = false;
          break;
        endif
      endfor
    endif
  endfor

  jsonl_size = file_sizes(1);
  c_flat_z0_size = file_sizes(2);

  % -------------------------------------------------------------------------------------
  % Report 1: Storage & Compression Efficiency
  % -------------------------------------------------------------------------------------
  printf("----------------------------------------------------------------------------------------\n");
  printf("  1. STORAGE & COMPRESSION EFFICIENCY (%d Samples)\n", num_samples);
  printf("----------------------------------------------------------------------------------------\n");
  printf("%-22s | %10s | %12s | %12s | %12s\n", ...
         "Configuration", "Size (KB)", "vs JSONL", "Space Saved", "vs Uncomp H5");
  printf("----------------------------------------------------------------------------------------\n");

  for c = 1:num_configs
    cfg = configs{c};
    sz_kb = file_sizes(c) / 1024.0;
    ratio_json = jsonl_size / file_sizes(c);
    saved_json = (1.0 - (file_sizes(c) / jsonl_size)) * 100.0;
    ratio_raw = c_flat_z0_size / file_sizes(c);

    if c == 1
      printf("%-22s | %10.2f | %11.2fx | %11.1f%% | %11.2fx\n", ...
             cfg.name, sz_kb, 1.0, 0.0, c_flat_z0_size / jsonl_size);
    else
      printf("%-22s | %10.2f | %11.2fx | %+11.1f%% | %11.2fx\n", ...
             cfg.name, sz_kb, ratio_json, saved_json, ratio_raw);
    endif
  endfor
  printf("----------------------------------------------------------------------------------------\n\n");

  % -------------------------------------------------------------------------------------
  % Report 2: Runtime Efficiency (Write & Read Throughput)
  % -------------------------------------------------------------------------------------
  printf("----------------------------------------------------------------------------------------\n");
  printf("  2. RUNTIME EFFICIENCY & THROUGHPUT (Average over %d runs)\n", num_reps);
  printf("----------------------------------------------------------------------------------------\n");
  printf("%-22s | %10s | %12s | %10s | %12s | %8s\n", ...
         "Configuration", "Write (ms)", "Write Thruput", "Read (ms)", "Read Throughput", "Verify");
  printf("----------------------------------------------------------------------------------------\n");

  for c = 1:num_configs
    cfg = configs{c};
    w_ms = write_times(c) * 1000.0;
    w_th = num_samples / write_times(c);
    r_ms = read_times(c) * 1000.0;
    r_th = num_samples / read_times(c);
    ver = "FAIL";
    if data_matches(c)
      ver = "PASS";
    endif

    printf("%-22s | %10.2f | %9.0f s/s | %10.2f | %9.0f s/s | %8s\n", ...
           cfg.name, w_ms, w_th, r_ms, r_th, ver);
  endfor
  printf("----------------------------------------------------------------------------------------\n\n");

  % -------------------------------------------------------------------------------------
  % Report 3: Speedup Analysis vs Baseline
  % -------------------------------------------------------------------------------------
  json_w_time = write_times(1);
  json_r_time = read_times(1);
  c_flat_z4_idx = 3; % C++ Flat z=4

  printf("----------------------------------------------------------------------------------------\n");
  printf("  3. KEY ARCHITECTURAL TAKEAWAYS & SPEEDUP SUMMARY\n");
  printf("----------------------------------------------------------------------------------------\n");
  printf("  * C++ Flat (z=4) vs JSONL Baseline:\n");
  printf("      - Compression:       %.2fx smaller (%.1f%% space saved)\n", ...
         jsonl_size / file_sizes(c_flat_z4_idx), (1 - file_sizes(c_flat_z4_idx)/jsonl_size)*100);
  printf("      - Write Performance: %.2fx faster (%.2f ms vs %.2f ms)\n", ...
         json_w_time / write_times(c_flat_z4_idx), write_times(c_flat_z4_idx)*1000, json_w_time*1000);
  printf("      - Read Performance:  %.2fx faster (%.2f ms vs %.2f ms)\n", ...
         json_r_time / read_times(c_flat_z4_idx), read_times(c_flat_z4_idx)*1000, json_r_time*1000);
  printf("\n");
  printf("  * Flat Layout vs Groups Layout (C++, z=4):\n");
  c_grp_z4_idx = 7;
  printf("      - Flat file size:    %.2f KB vs Groups: %.2f KB (%.2fx more compact)\n", ...
         file_sizes(c_flat_z4_idx)/1024, file_sizes(c_grp_z4_idx)/1024, file_sizes(c_grp_z4_idx)/file_sizes(c_flat_z4_idx));
  printf("      - Flat Write speed:  %.2fx faster (%.2f ms vs %.2f ms)\n", ...
         write_times(c_grp_z4_idx)/write_times(c_flat_z4_idx), write_times(c_flat_z4_idx)*1000, write_times(c_grp_z4_idx)*1000);
  printf("      - Flat Read speed:   %.2fx faster (%.2f ms vs %.2f ms)\n", ...
         read_times(c_grp_z4_idx)/read_times(c_flat_z4_idx), read_times(c_flat_z4_idx)*1000, read_times(c_grp_z4_idx)*1000);
  printf("\n");
  printf("  * C++ Acceleration vs Pure GNU Octave Fallback (Flat Layout):\n");
  oct_flat_idx = 10;
  printf("      - Write Acceleration: %.2fx faster in C++ (%.2f ms vs %.2f ms)\n", ...
         write_times(oct_flat_idx)/write_times(2), write_times(2)*1000, write_times(oct_flat_idx)*1000);
  printf("      - Read Acceleration:  %.2fx faster in C++ (%.2f ms vs %.2f ms)\n", ...
         read_times(oct_flat_idx)/read_times(2), read_times(2)*1000, read_times(oct_flat_idx)*1000);
  printf("========================================================================================\n\n");

  % Clean up
  confirm_recursive_rmdir(false, "local");
  rmdir(test_dir, "s");
endfunction

function write_jsonl_dataset(samples, filepath)
  fid = fopen(filepath, "w");
  if fid < 0
    error("Failed to open %s", filepath);
  endif
  for i = 1:length(samples)
    s = samples{i};
    line = jsonencode(s);
    fputs(fid, [line, "\n"]);
  endfor
  fclose(fid);
endfunction

if !isdeployed() && length(program_name()) > 0
  benchmark_hdf5(100);
endif
