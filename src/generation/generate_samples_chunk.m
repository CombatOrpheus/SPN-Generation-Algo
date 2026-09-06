## Copyright (C) 2026
##
## Author: SPN-Algo-Octave Authors
## Keywords: stochastic petri nets, sample generation, chunk worker

## -*- texinfo -*-
## @deftypefn {} {[@var{generated_count}, @var{attempts}, @var{results}] =} generate_samples_chunk (@var{config}, @var{target_samples}, @var{output_file}, @var{worker_id}, @var{quiet})
##
## Generate a chunk of @var{target_samples} valid SPN samples and write them to @var{output_file}.
##
## Inputs:
##   @var{config}: Configuration struct specifying net and analysis parameters
##   @var{target_samples}: Number of valid samples to generate
##   @var{output_file}: Destination filepath to write JSONL lines
##   @var{worker_id}: Optional worker identifier for logging (default: 1)
##   @var{quiet}: Optional flag to silence progress reporting (default: false)
##
## Outputs:
##   @var{generated_count}: Number of valid samples generated and written
##   @var{attempts}: Total number of generation attempts performed
##   @var{results}: Cell array of summary structs (for statistics reporting)
## @end deftypefn

function [generated_count, attempts, results] = generate_samples_chunk(config, target_samples, output_file, worker_id, quiet)
  if nargin < 4 || isempty(worker_id)
    worker_id = 1;
  endif
  if nargin < 5 || isempty(quiet)
    quiet = false;
  endif

  exact_mode = isfield(config, "exact_samples") && config.exact_samples;
  max_attempts = target_samples;
  if exact_mode
    max_attempts = target_samples * 20;
  endif

  out_dir = fileparts(output_file);
  if !isempty(out_dir) && !exist(out_dir, "dir")
    mkdir(out_dir);
  endif

  fid = fopen(output_file, "w");
  if fid < 0
    error("Failed to open worker output file: %s", output_file);
  endif

  alloc_capacity = target_samples;
  if isfield(config, "enable_transformations") && config.enable_transformations && isfield(config, "max_transforms_per_sample")
    alloc_capacity = target_samples * config.max_transforms_per_sample;
  endif
  results = cell(alloc_capacity, 1);
  generated_count = 0;
  attempts = 0;

  while generated_count < target_samples && attempts < max_attempts
    attempts = attempts + 1;

    pn = petrinet_generate_random(config.num_places, config.num_transitions);
    pn = petrinet_prune(pn);
    pn = petrinet_add_tokens_randomly(pn);

    rg = generate_reachability_graph(pn, config.place_upper_bound, config.marks_upper_limit);

    if !rg.is_bounded || rg.num_vertices < config.marks_lower_limit
      continue;
    endif

    lambda_values = double(randi([config.min_firing_rate, config.max_firing_rate], pn.transitions, 1));
    [probs, err] = solve_steady_state(rg, lambda_values);
    if err
      continue;
    endif

    [avg_markings, densities] = compute_average_markings(rg, probs);

    if isfield(config, "enable_transformations") && config.enable_transformations
      variations = generate_petrinet_variations(pn, config.place_upper_bound, config.marks_lower_limit, ...
                                               config.marks_upper_limit, config.max_transforms_per_sample, ...
                                               config.min_firing_rate, config.max_firing_rate);

      for v_idx = 1:length(variations)
        if exact_mode && generated_count >= target_samples
          break;
        endif
        var_res = variations{v_idx};
        write_sample_jsonl(fid, var_res.petri_net, var_res.reachability_graph, var_res.lambda_values, ...
                           var_res.steady_state_probs, var_res.average_markings, var_res.marking_densities);

        r = struct();
        r.num_places = var_res.petri_net.places;
        r.num_transitions = var_res.petri_net.transitions;
        r.average_markings = var_res.average_markings;
        r.steady_state_probs = var_res.steady_state_probs;
        generated_count = generated_count + 1;
        if generated_count > length(results)
          results{generated_count * 2} = [];
        endif
        results{generated_count} = r;
      endfor
    else
      write_sample_jsonl(fid, pn, rg, lambda_values, probs, avg_markings, densities);

      r = struct();
      r.num_places = pn.places;
      r.num_transitions = pn.transitions;
      r.average_markings = avg_markings;
      r.steady_state_probs = probs;
      generated_count = generated_count + 1;
      if generated_count > length(results)
        results{generated_count * 2} = [];
      endif
      results{generated_count} = r;
    endif

    if !quiet && (generated_count == target_samples || mod(generated_count, max(1, floor(target_samples / 5))) == 0)
      printf("[Worker %d] Generated %d/%d samples (attempt %d)...\n", ...
             worker_id, generated_count, target_samples, attempts);
      fflush(stdout);
    endif
  endwhile

  results = results(1:generated_count);
  fclose(fid);
endfunction
