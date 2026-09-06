## Copyright (C) 2026
##
## Author: SPN-Algo-Octave Authors
## Keywords: stochastic petri nets, parallel processing, multiprocessing

## -*- texinfo -*-
## @deftypefn {} {[@var{total_written}, @var{stats}] =} generate_parallel_dataset (@var{config}, @var{num_workers}, @var{output_file})
##
## Generate an SPN dataset in parallel using POSIX fork and waitpid multiprocessing.
##
## Inputs:
##   @var{config}: Generation and analysis configuration struct
##   @var{num_workers}: Number of parallel worker processes ("auto", integer, or 1 for sequential)
##   @var{output_file}: Target destination filepath for final combined JSONL dataset
##
## Outputs:
##   @var{total_written}: Total number of valid samples written to @var{output_file}
##   @var{stats}: Computed dataset summary statistics struct
## @end deftypefn

function [total_written, stats] = generate_parallel_dataset(config, num_workers, output_file)
  if nargin < 2 || isempty(num_workers)
    if isfield(config, "num_workers")
      num_workers = config.num_workers;
    else
      num_workers = "auto";
    endif
  endif

  if nargin < 3 || isempty(output_file)
    output_file = config.output_file;
  endif

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

  % Single worker or single sample: execute directly without forking
  if W <= 1 || target_samples == 1
    if !quiet
      printf("Running in single-process mode (%d sample(s))...\n", target_samples);
    endif
    [total_written, attempts, results] = generate_samples_chunk(config, target_samples, output_file, 1, quiet);
    if !quiet
      printf("Completed! Wrote %d samples (in %d attempts) to %s\n", total_written, attempts, output_file);
    endif

    if isfield(config, "enable_statistics_report") && config.enable_statistics_report
      stats = calculate_stats(results);
      report_path = [output_file, ".html"];
      generate_html_report(report_path, stats);
      if !quiet
        printf("Generated HTML statistics report: %s\n", report_path);
        printf("Stats: %d samples, avg places=%.2f, avg trans=%.2f, avg markings=%.2f\n", ...
               stats.num_samples, stats.avg_places, stats.avg_transitions, stats.avg_markings);
      endif
    else
      stats = struct();
    endif
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
      rand("seed", worker_seed);
      randn("seed", worker_seed);
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

  % Optional HTML report and stats calculation
  if isfield(config, "enable_statistics_report") && config.enable_statistics_report
    samples = load_jsonl(output_file);
    results = cell(length(samples), 1);
    for k = 1:length(samples)
      s = samples{k};
      r = struct();
      if isstruct(s.petri_net)
        r.num_places = s.petri_net.places;
        r.num_transitions = s.petri_net.transitions;
      else
        % s.petri_net is the P x 2T matrix
        r.num_places = size(s.petri_net, 1);
        r.num_transitions = size(s.petri_net, 2) / 2;
      endif
      r.average_markings = s.average_markings;
      r.steady_state_probs = s.steady_state_probs;
      results{k} = r;
    endfor

    stats = calculate_stats(results);
    report_path = [output_file, ".html"];
    generate_html_report(report_path, stats);
    if !quiet
      printf("Generated HTML statistics report: %s\n", report_path);
      printf("Stats: %d samples, avg places=%.2f, avg trans=%.2f, avg markings=%.2f\n", ...
             stats.num_samples, stats.avg_places, stats.avg_transitions, stats.avg_markings);
    endif
  else
    stats = struct();
  endif
endfunction
