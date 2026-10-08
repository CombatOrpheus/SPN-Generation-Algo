## -*- texinfo -*-
## @deftypefn {} {@var{cfg} =} get_default_config ()
## Return default configuration struct for SPN dataset generation and analysis.
##
## Defines standard parameter defaults for net topology, state space limits,
## rate bounds, parallel execution, and output formats.
##
## Returns struct @var{cfg}.
##
## @seealso{validate_config, load_json}
## @end deftypefn
function cfg = get_default_config()
  cfg = struct();
  cfg.generation_mode = "random";
  cfg.num_places = 5;
  cfg.num_transitions = 3;
  cfg.num_samples = 100;
  cfg.num_workers = "auto";
  cfg.exact_samples = true;
  cfg.seed = [];
  cfg.output_file = "spn_dataset.jsonl";
  cfg.format = "jsonl";
  cfg.hdf5_compression_level = 4;
  cfg.place_upper_bound = 10;
  cfg.marks_lower_limit = 4;
  cfg.marks_upper_limit = 500;
  cfg.min_firing_rate = 1;
  cfg.max_firing_rate = 10;
  cfg.enable_transformations = true;
  cfg.max_transforms_per_sample = 5;
  cfg.enable_statistics_report = true;
  cfg.places_grid_boundaries = [5, 7, 9, 11, 13];
  cfg.markings_grid_boundaries = [4, 8, 12, 16, 20, 24, 28, 32, 36, 40];
  cfg.samples_per_grid = 10;
  cfg.lambda_variations_per_sample = 5;
  cfg.accumulation_data = false;
  cfg.temporary_grid_location = "temp_grid";
  cfg.output_grid_location = "grid_data.jsonl";
  cfg.quiet = false;
endfunction
