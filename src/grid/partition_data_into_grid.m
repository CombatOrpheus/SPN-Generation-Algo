## -*- texinfo -*-
## @deftypefn {} {} partition_data_into_grid (@var{grid_dir}, @var{accumulate_data}, @var{raw_data_path}, @var{places_boundaries}, @var{markings_boundaries})
## Partition raw SPN dataset into a 2D place-marking grid directory structure.
##
## Stratifies samples across two dimensions (number of places and number of reachable markings)
## into directories @file{p@{i@}/m@{j@}/}, writing separate JSON files per net.
##
## @table @asis
## @item @var{grid_dir}
## Root output directory for grid partitions.
##
## @item @var{accumulate_data}
## Logical scalar. If true, updates existing bins without clearing previous count matrices.
##
## @item @var{raw_data_path}
## Path to source JSONL dataset file.
##
## @item @var{places_boundaries}
## Ascending vector of boundary thresholds defining place bins.
##
## @item @var{markings_boundaries}
## Ascending vector of boundary thresholds defining marking count bins.
## @end table
##
## @seealso{sample_and_transform_data}
## @end deftypefn
function partition_data_into_grid(grid_dir, accumulate_data, raw_data_path, places_boundaries, markings_boundaries)

  num_p_bins = length(places_boundaries) + 1;
  num_m_bins = length(markings_boundaries) + 1;

  config_path = fullfile(grid_dir, "config.json");
  if accumulate_data && exist(config_path, "file")
    grid_config = load_json(config_path);
    json_count = grid_config.json_count;
  else
    json_count = zeros(num_p_bins, num_m_bins);
  endif

  fid = fopen(raw_data_path, "r");
  if fid < 0
    error("Failed to open raw data file: %s", raw_data_path);
  endif

  % Pre-sort boundaries to ensure monotonic order for lookup
  p_bounds = sort(places_boundaries(:)');
  m_bounds = sort(markings_boundaries(:)');

  while !feof(fid)
    line = fgetl(fid);
    if !ischar(line) || isempty(strtrim(line))
      continue;
    endif

    sample = jsondecode(line);

    % Determine places and markings count
    num_p = size(sample.petri_net, 1);
    num_m = size(sample.vertices, 1);

    % Find bin index (1-based) using fast O(log N) lookup
    p_idx = lookup(p_bounds, num_p) + 1;
    m_idx = lookup(m_bounds, num_m) + 1;

    json_count(p_idx, m_idx) = json_count(p_idx, m_idx) + 1;
    count = json_count(p_idx, m_idx);

    cell_dir = fullfile(grid_dir, sprintf("p%d", p_idx), sprintf("m%d", m_idx));
    if !exist(cell_dir, "dir")
      mkdir(cell_dir);
    endif

    file_path = fullfile(cell_dir, sprintf("data%d.json", count));
    save_json(file_path, sample);
  endwhile
  fclose(fid);

  grid_config = struct();
  grid_config.row_p = places_boundaries;
  grid_config.col_m = markings_boundaries;
  grid_config.json_count = json_count;

  save_json(config_path, grid_config);
endfunction
