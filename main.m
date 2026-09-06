## -*- texinfo -*-
## @deftypefn {} {} main (@var{varargin})
## CLI and program entry point for SPN Benchmark Dataset Generator.
##
## Parses command-line arguments, validates configurations, sets up reproducible RNG seeds,
## and invokes the parallel dataset generation pipeline.
##
## Supported command-line options:
## @table @option
## @item --config <path>
## Path to JSON configuration file (default: @file{config.json}).
## @item --workers <N>, -j <N>
## Number of worker processes ("auto", 1, or integer).
## @item --mode <mode>
## Generation mode: "random" or "grid".
## @item --samples <N>
## Number of valid samples to generate.
## @item --output <path>
## Output file destination path (.jsonl).
## @item --seed <N>
## Integer RNG seed for reproducible generation.
## @item --exact
## Generate exactly @var{samples} nets without rate variations.
## @item --report <path>
## Optional HTML summary report path.
## @end table
##
## @seealso{generate_parallel_dataset, validate_config}
## @end deftypefn
function main(varargin)
  ignore_function_time_stamp("all");

  if nargin == 0 && length(argv()) > 0
    varargin = argv();
  endif

  config_path = "config.json";

  % Overrides from CLI
  cli_mode = "";
  cli_samples = -1;
  cli_output = "";
  cli_seed = [];
  cli_exact = [];
  cli_workers = "";

  % Parse CLI args
  i = 1;
  while i <= length(varargin)
    arg = varargin{i};
    if strcmp(arg, "--config") && i < length(varargin)
      config_path = varargin{i + 1};
      i = i + 2;
    elseif (strcmp(arg, "--workers") || strcmp(arg, "-j")) && i < length(varargin)
      cli_workers = varargin{i + 1};
      i = i + 2;
    elseif strcmp(arg, "--mode") && i < length(varargin)
      cli_mode = varargin{i + 1};
      i = i + 2;
    elseif strcmp(arg, "--samples") && i < length(varargin)
      cli_samples = str2double(varargin{i + 1});
      i = i + 2;
    elseif strcmp(arg, "--output") && i < length(varargin)
      cli_output = varargin{i + 1};
      i = i + 2;
    elseif strcmp(arg, "--seed") && i < length(varargin)
      cli_seed = str2double(varargin{i + 1});
      i = i + 2;
    elseif strcmp(arg, "--exact")
      cli_exact = true;
      i = i + 1;
    elseif strcmp(arg, "--no-exact")
      cli_exact = false;
      i = i + 1;
    elseif strcmp(arg, "--help") || strcmp(arg, "-h")
      print_usage();
      return;
    else
      i = i + 1;
    endif
  endwhile

  if !exist(config_path, "file")
    error("Configuration file not found: %s", config_path);
  endif

  printf("Loading configuration from: %s\n", config_path);
  config = load_json(config_path);

  % Apply CLI overrides
  if !isempty(cli_mode)
    config.generation_mode = cli_mode;
  endif
  if cli_samples > 0
    config.num_samples = cli_samples;
  endif
  if !isempty(cli_output)
    if strcmp(config.generation_mode, "grid")
      config.output_grid_location = cli_output;
    else
      config.output_file = cli_output;
    endif
  endif
  if !isempty(cli_seed)
    config.seed = cli_seed;
  endif
  if !isempty(cli_exact)
    config.exact_samples = cli_exact;
  elseif !isfield(config, "exact_samples")
    config.exact_samples = true;
  endif
  if !isempty(cli_workers)
    config.num_workers = cli_workers;
  elseif !isfield(config, "num_workers")
    config.num_workers = "auto";
  endif

  % Validate configuration parameters before execution
  validate_config(config);

  % Initialize RNG seed if configured
  if isfield(config, "seed") && !isempty(config.seed)
    rand("state", config.seed);
    randn("state", config.seed);
    printf("RNG seed initialized to: %d\n", config.seed);
  endif

  if strcmp(config.generation_mode, "grid")
    run_grid_generation(config);
  else
    run_random_generation(config);
  endif
endfunction

function print_usage()
  printf("Usage: octave main.m [OPTIONS]\n\n");
  printf("Options:\n");
  printf("  --config <path>    Path to JSON configuration file (default: config.json)\n");
  printf("  --mode <mode>      Generation mode: 'random' or 'grid'\n");
  printf("  --samples <N>      Number of samples to generate\n");
  printf("  --output <path>    Output file destination path\n");
  printf("  --workers, -j <N>  Number of parallel workers ('auto' or integer, default: auto)\n");
  printf("  --seed <N>         Random number generator seed for reproducibility\n");
  printf("  --exact            Ensure exact target sample count via retries (default)\n");
  printf("  --no-exact         Do not retry invalid nets (fixed attempt count)\n");
  printf("  --help, -h         Show this help message\n");
endfunction

function run_random_generation(config)
  num_workers = "auto";
  if isfield(config, "num_workers")
    num_workers = config.num_workers;
  endif
  generate_parallel_dataset(config, num_workers, config.output_file);
endfunction

function run_grid_generation(config)
  printf("Starting grid-based SPN generation\n");

  temp_dir = config.temporary_grid_location;
  if !exist(temp_dir, "dir")
    mkdir(temp_dir);
  endif

  raw_path = fullfile(temp_dir, "raw_data.jsonl");

  % 1. Generate raw data
  fid = fopen(raw_path, "w");
  if fid < 0
    error("Failed to open raw data file: %s", raw_path);
  endif

  raw_count = 0;
  raw_target = config.num_samples;
  attempts = 0;
  max_attempts = raw_target * 20;

  printf("Generating raw Petri nets for grid partitioning...\n");
  while raw_count < raw_target && attempts < max_attempts
    attempts = attempts + 1;

    pn = petrinet_generate_random(config.num_places, config.num_transitions);
    pn = petrinet_prune(pn);
    pn = petrinet_add_tokens_randomly(pn);

    rg = generate_reachability_graph(pn, config.place_upper_bound, config.marks_upper_limit);
    if !rg.is_bounded || rg.num_vertices < config.marks_lower_limit
      continue;
    endif

    write_sample_jsonl(fid, pn, rg, [], [], [], {});
    raw_count = raw_count + 1;

    if mod(raw_count, max(1, floor(raw_target / 5))) == 0
      printf("[Grid Raw] Generated %d/%d raw nets (attempt %d)...\n", raw_count, raw_target, attempts);
    endif
  endwhile
  fclose(fid);
  printf("Raw data generation complete: %d nets saved to %s\n", raw_count, raw_path);

  % 2. Partition data into grid (streaming)
  printf("Partitioning raw data into grid cells...\n");
  partition_data_into_grid(temp_dir, config.accumulation_data, raw_path, ...
                           config.places_grid_boundaries, config.markings_grid_boundaries);

  % 3. Sample and transform data
  printf("Sampling and transforming grid data with lambda variations...\n");
  results = sample_and_transform_data(temp_dir, config.samples_per_grid, ...
                                      config.lambda_variations_per_sample, ...
                                      config.min_firing_rate, config.max_firing_rate);

  % 4. Write output dataset
  out_fid = fopen(config.output_grid_location, "w");
  if out_fid < 0
    error("Failed to open output grid file: %s", config.output_grid_location);
  endif

  for i = 1:length(results)
    s = results{i};
    write_sample_jsonl(out_fid, s.petri_net, s.reachability_graph, s.lambda_values, ...
                       s.steady_state_probs, s.average_markings, s.marking_densities);
  endfor
  fclose(out_fid);

  printf("Grid generation complete: %d samples saved to %s\n", length(results), config.output_grid_location);
endfunction
