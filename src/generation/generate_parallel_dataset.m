## Copyright (C) 2026
##
## Author: SPN-Algo-Octave Authors
## Keywords: stochastic petri nets, parallel processing, multiprocessing

## -*- texinfo -*-
## @deftypefn {} {[@var{total_written}, @var{stats}] =} generate_parallel_dataset (@var{config})
## @deftypefnx {} {[@var{total_written}, @var{stats}] =} generate_parallel_dataset (@var{config}, @var{num_workers})
## @deftypefnx {} {[@var{total_written}, @var{stats}] =} generate_parallel_dataset (@var{config}, @var{num_workers}, @var{output_file})
## Generate an SPN dataset in parallel using POSIX fork and waitpid multiprocessing.
##
## Spawns worker processes that independently generate valid bounded Stochastic Petri Nets,
## compute reachability graphs and steady-state distributions, and stream JSONL output.
## When POSIX fork is unavailable or on Windows, gracefully falls back to sequential execution.
##
## @table @asis
## @item @var{config}
## Generation and analysis configuration struct.
##
## @item @var{num_workers}
## Number of parallel worker processes ("auto", positive integer, or 1 for sequential).
##
## @item @var{output_file}
## Target destination filepath for final combined JSONL dataset.
## @end table
##
## Outputs:
## @table @asis
## @item @var{total_written}
## Total number of valid samples written to @var{output_file}.
##
## @item @var{stats}
## Computed dataset summary statistics struct.
## @end table
##
## @seealso{generate_samples_chunk, validate_config, calculate_stats}
## @end deftypefn

function [total_written, stats] = generate_parallel_dataset(config, num_workers, output_file)
  config = validate_config(config);

  if nargin >= 2 && !isempty(num_workers)
    config.num_workers = num_workers;
  endif
  num_workers = config.num_workers;

  if nargin >= 3 && !isempty(output_file)
    config.output_file = output_file;
  endif
  output_file = config.output_file;

  % Resolve worker count
  if ischar(num_workers)
    if strcmp(num_workers, "auto")
      W = nproc();
    else
      W = str2double(num_workers);
      if isnan(W) || W < 1
        W = nproc();
      else
        W = floor(W);
      endif
    endif
  elseif isnumeric(num_workers)
    W = max(1, floor(num_workers));
  else
    W = nproc();
  endif

  target_samples = config.num_samples;
  if target_samples <= 0
    fid = fopen(output_file, "w");
    if fid >= 0
      fclose(fid);
    endif
    total_written = 0;
    stats = struct("num_samples", 0, "avg_places", 0, "avg_transitions", 0, "avg_markings", 0);
    return;
  endif

  quiet = isfield(config, "quiet") && config.quiet;
  has_fork = (exist("fork", "builtin") == 5);

  % Single worker or single sample or no fork available: execute directly without forking
  if !has_fork || W <= 1 || target_samples == 1
    if !quiet
      if !has_fork && W > 1
        printf("Notice: fork() is not available on this platform. Running in single-process mode (%d sample(s))...\n", target_samples);
      else
        printf("Running in single-process mode (%d sample(s))...\n", target_samples);
      endif
    endif
    [total_written, attempts, results] = generate_samples_chunk(config, target_samples, output_file, 1, quiet);
    if !quiet
      printf("Completed! Wrote %d samples (in %d attempts) to %s\n", total_written, attempts, output_file);
    endif

    stats = finalize_dataset(config, output_file, total_written, results, quiet);
    return;
  endif

  % Bound workers to target samples
  W = min(W, target_samples);

  % Partition sample counts evenly across workers
  base_count = floor(target_samples / W);
  rem_count = mod(target_samples, W);
  worker_targets = repmat(base_count, 1, W);
  worker_targets(1:rem_count) = worker_targets(1:rem_count) + 1;

  % Filter out any workers with 0 targets
  active_idx = find(worker_targets > 0);
  W = length(active_idx);
  worker_targets = worker_targets(active_idx);

  temp_dir = tempdir();
  part_files = cell(W, 1);
  for i = 1:W
    part_files{i} = fullfile(temp_dir, sprintf("spn_part_%d_%d_%d.jsonl", getpid(), floor(time()), i));
  endfor

  % Derive base seed
  if isfield(config, "seed") && !isempty(config.seed)
    base_seed = config.seed;
  else
    base_seed = randi([1, 1000000]);
  endif

  if !quiet
    printf("Starting parallel generation with %d workers (targets: %s)\n", W, mat2str(worker_targets));
    fflush(stdout);
  endif

  pids = zeros(W, 1);
  for i = 1:W
    worker_seed = mod(base_seed + (i - 1) * 10007, 2147483647);
    [pid, msg] = fork();

    if pid < 0
      error("fork() failed for worker %d: %s", i, msg);
    elseif pid == 0
      % CHILD WORKER PROCESS
      rand("state", worker_seed);
      randn("state", worker_seed);
      try
        generate_samples_chunk(config, worker_targets(i), part_files{i}, i, quiet);
        _Exit(0);
      catch err
        fprintf(stderr, "Fatal error in worker %d: %s\n", i, err.message);
        _Exit(1);
      end_try_catch
    else
      % PARENT PROCESS
      pids(i) = pid;
    endif
  endfor

  % Parent waits for all child workers to terminate
  worker_errors = 0;
  for i = 1:W
    [wpid, status, msg] = waitpid(pids(i));
    if WIFEXITED(status)
      exit_code = WEXITSTATUS(status);
      if exit_code != 0
        worker_errors = worker_errors + 1;
        fprintf(stderr, "Worker %d (PID %d) exited with error code %d\n", i, wpid, exit_code);
      endif
    else
      worker_errors = worker_errors + 1;
      fprintf(stderr, "Worker %d (PID %d) terminated abnormally\n", i, wpid);
    endif
  endfor

  if worker_errors > 0
    % Cleanup temp files
    for i = 1:W
      if exist(part_files{i}, "file")
        delete(part_files{i});
      endif
    endfor
    error("One or more parallel workers failed during generation.");
  endif

  % Ensure output directory exists
  out_dir = fileparts(output_file);
  if !isempty(out_dir) && !exist(out_dir, "dir")
    mkdir(out_dir);
  endif

  % Concatenate partition files into final output file
  out_fid = fopen(output_file, "w");
  if out_fid < 0
    error("Failed to open destination output file: %s", output_file);
  endif

  total_written = 0;
  for i = 1:W
    part_path = part_files{i};
    if exist(part_path, "file")
      pfid = fopen(part_path, "r");
      if pfid >= 0
        while true
          line = fgetl(pfid);
          if !ischar(line)
            break;
          endif
          fputs(out_fid, [line, "\n"]);
          total_written = total_written + 1;
        endwhile
        fclose(pfid);
        delete(part_path);
      endif
    endif
  endfor
  fclose(out_fid);

  if !quiet
    printf("Parallel generation completed! Wrote %d samples to %s\n", total_written, output_file);
  endif

  stats = finalize_dataset(config, output_file, total_written, {}, quiet);
endfunction

function stats = finalize_dataset(config, output_file, total_written, results, quiet)
  % 1. Optional HTML report and stats calculation
  if isfield(config, "enable_statistics_report") && config.enable_statistics_report
    if !isempty(results)
      stats = calculate_stats(results);
    else
      stats = compute_streaming_stats_jsonl(output_file);
    endif
    report_path = [output_file, ".html"];
    generate_html_report(report_path, stats);
    if !quiet
      printf("\nGenerated HTML statistics report: %s\n", report_path);
      table_str = format_stats_table(stats);
      printf("%s\n", table_str);
    endif
  else
    stats = struct();
  endif

  % 2. HDF5 export if requested
  fmt = "jsonl";
  if isfield(config, "format") && !isempty(config.format)
    fmt = config.format;
  endif

  if strcmp(fmt, "hdf5") || strcmp(fmt, "both")
    if regexpi(output_file, '\.h5$')
      h5_file = output_file;
    else
      h5_file = regexprep(output_file, '\.jsonl$', '.h5');
      if strcmp(h5_file, output_file)
        h5_file = [output_file, ".h5"];
      endif
    endif

    comp_lvl = 4;
    if isfield(config, "hdf5_compression_level") && !isempty(config.hdf5_compression_level)
      comp_lvl = config.hdf5_compression_level;
    endif

    % Export to HDF5
    if !isempty(results) && length(results) == total_written
      export_dataset_hdf5(results, h5_file, comp_lvl);
    else
      export_dataset_hdf5(output_file, h5_file, comp_lvl);
    endif

    if !quiet
      printf("Exported HDF5 dataset (flat layout, compression %d) to: %s\n", comp_lvl, h5_file);
    endif

    if strcmp(fmt, "hdf5") && !strcmp(output_file, h5_file) && exist(output_file, "file")
      delete(output_file);
    endif
  endif
endfunction

function stats = compute_streaming_stats_jsonl(file_path)
  if !exist(file_path, "file")
    stats = calculate_stats({});
    return;
  endif
  samples = load_jsonl(file_path);
  stats = calculate_stats(samples);
endfunction
