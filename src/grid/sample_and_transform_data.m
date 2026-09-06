function transformed_samples = sample_and_transform_data(grid_dir, samples_per_grid, lambda_variations_per_sample, min_firing_rate, max_firing_rate)
  % SAMPLE_AND_TRANSFORM_DATA Samples Petri nets from grid cells and generates variations.
  %
  % Inputs:
  %   grid_dir                     - Root directory of partitioned grid
  %   samples_per_grid             - Number of samples to take per cell
  %   lambda_variations_per_sample - Number of lambda rate variations to generate per sample
  %   min_firing_rate              - Minimum firing rate
  %   max_firing_rate              - Maximum firing rate
  %
  % Outputs:
  %   transformed_samples          - Cell array of transformed sample structs

  config_path = fullfile(grid_dir, "config.json");
  if !exist(config_path, "file")
    error("Grid config not found: %s", config_path);
  endif

  grid_config = load_json(config_path);
  num_p_bins = length(grid_config.row_p) + 1;
  num_m_bins = length(grid_config.col_m) + 1;

  max_transformed = num_p_bins * num_m_bins * samples_per_grid * lambda_variations_per_sample;
  transformed_samples = cell(max_transformed, 1);
  ts_count = 0;

  for i = 1:num_p_bins
    for j = 1:num_m_bins
      cell_dir = fullfile(grid_dir, sprintf("p%d", i), sprintf("m%d", j));
      if !exist(cell_dir, "dir")
        continue;
      endif

      files = dir(fullfile(cell_dir, "data*.json"));
      if isempty(files)
        continue;
      endif

      % Random shuffle files
      perm = randperm(length(files));
      num_to_take = min(samples_per_grid, length(files));

      for k = 1:num_to_take
        sample_file = fullfile(cell_dir, files(perm(k)).name);
        data = load_json(sample_file);

        % Reconstruct pn and rg structs
        pn = struct();
        pn.places = size(data.petri_net, 1);
        pn.transitions = (size(data.petri_net, 2) - 1) / 2;
        pn.matrix = int32(data.petri_net);
        pn.initial_marking = pn.matrix(:, end);

        rg = struct();
        rg.vertices = int32(data.vertices);
        if isvector(rg.vertices) && size(rg.vertices, 1) == 1
          rg.vertices = rg.vertices(:)';
        endif

        % In JSON, edges are 0-based
        raw_edges = data.edges;
        if iscell(raw_edges)
          raw_edges = cell2mat(raw_edges);
        endif
        raw_edges = double(raw_edges);
        if isempty(raw_edges)
          rg.edges = zeros(0, 2, "int32");
        elseif size(raw_edges, 2) == 2
          rg.edges = int32(raw_edges) + 1;
        elseif numel(raw_edges) == 2
          rg.edges = int32(reshape(raw_edges, 1, 2)) + 1;
        else
          rg.edges = int32(reshape(raw_edges, [], 2)) + 1;
        endif
        rg.arc_transitions = int32(data.arc_transitions(:)) + 1;
        rg.num_vertices = size(rg.vertices, 1);
        rg.num_edges = size(rg.edges, 1);
        rg.is_bounded = true;

        [variations, lambdas] = generate_lambda_variations(pn, rg, lambda_variations_per_sample, min_firing_rate, max_firing_rate);

        for v_idx = 1:length(variations)
          var_res = variations{v_idx};
          ts = struct();
          ts.petri_net = pn;
          ts.reachability_graph = rg;
          ts.lambda_values = lambdas{v_idx};
          ts.steady_state_probs = var_res.steady_state_probs;
          ts.average_markings = var_res.average_markings;
          ts.marking_densities = var_res.marking_densities;

          ts_count = ts_count + 1;
          transformed_samples{ts_count} = ts;
        endfor
      endfor
    endfor
  endfor

  transformed_samples = transformed_samples(1:ts_count);
endfunction
