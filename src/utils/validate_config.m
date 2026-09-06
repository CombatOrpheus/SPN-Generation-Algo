## -*- texinfo -*-
## @deftypefn {} {} validate_config (@var{config})
## Validate dataset generation and analysis configuration struct.
##
## Checks configuration integrity, field presence, data types, and logical value bounds
## before execution starts. Throws an informative error if any validation check fails.
##
## @table @asis
## @item @var{config}
## Struct representing configuration loaded from JSON or CLI options.
## @end table
##
## @seealso{load_json, generate_parallel_dataset}
## @end deftypefn
function validate_config(config)

  if !isstruct(config)
    error("validate_config: Configuration must be a struct.");
  endif

  % 1. Mode
  if !isfield(config, "generation_mode") || !ischar(config.generation_mode) || ...
     (!strcmp(config.generation_mode, "random") && !strcmp(config.generation_mode, "grid"))
    error("validate_config: 'generation_mode' must be either 'random' or 'grid'.");
  endif

  % 2. Place & Transition counts
  if !isfield(config, "num_places") || !isnumeric(config.num_places) || config.num_places < 1
    error("validate_config: 'num_places' must be a positive integer >= 1.");
  endif
  if !isfield(config, "num_transitions") || !isnumeric(config.num_transitions) || config.num_transitions < 1
    error("validate_config: 'num_transitions' must be a positive integer >= 1.");
  endif

  % 3. Sample count
  if !isfield(config, "num_samples") || !isnumeric(config.num_samples) || config.num_samples < 0
    error("validate_config: 'num_samples' must be a non-negative integer >= 0.");
  endif

  % 4. State space bounds
  if !isfield(config, "place_upper_bound") || !isnumeric(config.place_upper_bound) || config.place_upper_bound < 1
    error("validate_config: 'place_upper_bound' must be an integer >= 1.");
  endif
  if !isfield(config, "marks_lower_limit") || !isnumeric(config.marks_lower_limit) || config.marks_lower_limit < 1
    error("validate_config: 'marks_lower_limit' must be an integer >= 1.");
  endif
  if !isfield(config, "marks_upper_limit") || !isnumeric(config.marks_upper_limit) || config.marks_upper_limit < config.marks_lower_limit
    error("validate_config: 'marks_upper_limit' (%d) must be >= 'marks_lower_limit' (%d).", ...
          config.marks_upper_limit, config.marks_lower_limit);
  endif

  % 5. Transition firing rates
  if !isfield(config, "min_firing_rate") || !isnumeric(config.min_firing_rate) || config.min_firing_rate <= 0
    error("validate_config: 'min_firing_rate' must be a positive number > 0.");
  endif
  if !isfield(config, "max_firing_rate") || !isnumeric(config.max_firing_rate) || config.max_firing_rate < config.min_firing_rate
    error("validate_config: 'max_firing_rate' (%g) must be >= 'min_firing_rate' (%g).", ...
          config.max_firing_rate, config.min_firing_rate);
  endif

  % 6. Grid mode specific validation
  if strcmp(config.generation_mode, "grid")
    if !isfield(config, "places_grid_boundaries") || !isnumeric(config.places_grid_boundaries) || isempty(config.places_grid_boundaries)
      error("validate_config: 'places_grid_boundaries' must be a non-empty numeric vector for grid mode.");
    endif
    if !issorted(config.places_grid_boundaries)
      error("validate_config: 'places_grid_boundaries' must be sorted in ascending order.");
    endif

    if !isfield(config, "markings_grid_boundaries") || !isnumeric(config.markings_grid_boundaries) || isempty(config.markings_grid_boundaries)
      error("validate_config: 'markings_grid_boundaries' must be a non-empty numeric vector for grid mode.");
    endif
    if !issorted(config.markings_grid_boundaries)
      error("validate_config: 'markings_grid_boundaries' must be sorted in ascending order.");
    endif

    if !isfield(config, "samples_per_grid") || !isnumeric(config.samples_per_grid) || config.samples_per_grid < 1
      error("validate_config: 'samples_per_grid' must be an integer >= 1.");
    endif
  endif
endfunction
