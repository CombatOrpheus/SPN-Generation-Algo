%% generate_dataset
%%
%% Generates a dataset of Stochastic Petri Nets (SPNs) based on a grid
%% configuration and saves them to files.
%%
%% This script can be called as a function within Octave/MATLAB or executed
%% from the command line. It systematically generates and validates SPNs,
%% binning them based on their structural and behavioral properties.
%%
%% Function Usage:
%%   generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
%%
%% Inputs:
%%   pn_range:      A 1x2 vector [min, max] for the number of places.
%%   tn_range:      A 1x2 vector [min, max] for the number of transitions.
%%   states_bins:   A vector defining upper boundaries for state bins.
%%                  e.g., [10, 50, 100] creates bins <10, 10-49, 50-99, >=100.
%%   spns_per_bin:  The target number of valid SPNs for each bin.
%%   output_dir:    A string path to the output directory.
%%
%% Example:
%%   generate_dataset([5, 10], [4, 8], [20, 100], 5, 'spn_dataset');
%%
%% Command-Line Interface (CLI) Usage:
%%   octave generate_dataset.m <pn_range> <tn_range> <states_bins> <spns_per_bin> <output_dir>
%%
%% CLI Arguments:
%%   <pn_range>:    String in the format "[min,max]". E.g., "[5,10]"
%%   <tn_range>:    String in the format "[min,max]". E.g., "[4,8]"
%%   <states_bins>: String in the format "[b1,b2,...]". E.g., "[20,100]"
%%   <spns_per_bin>:An integer. E.g., 5
%%   <output_dir>:  A string for the output path. E.g., "spn_dataset"
%%
%% CLI Example:
%%   octave generate_dataset.m "[5,10]" "[4,8]" "[20,100]" 5 "spn_dataset"
%%
%% Use 'octave generate_dataset.m --help' for more information.

function generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
  % --- CLI and Help Text Handling ---
  if (nargin == 0)
    args = argv();
    if any(strcmp(args, '--help')) || any(strcmp(args, '-h'))
      help('generate_dataset');
      return;
    endif

    % Check for the correct number of CLI arguments.
    if length(args) != 5
      error('Invalid number of arguments. Expected 5, but got %d. Use --help for usage.', length(args));
    endif

    % Parse string arguments from CLI.
    pn_range_cli = str2num(args{1});
    tn_range_cli = str2num(args{2});
    states_bins_cli = str2num(args{3});
    spns_per_bin_cli = str2double(args{4});
    output_dir_cli = args{5};

    % Call the implementation function with the parsed arguments.
    generate_dataset_impl(pn_range_cli, tn_range_cli, states_bins_cli, spns_per_bin_cli, output_dir_cli);
  else
    % Standard function call.
    generate_dataset_impl(pn_range, tn_range, states_bins, spns_per_bin, output_dir);
  endif
endfunction

% --- Core Implementation ----------------------------------------------------
function generate_dataset_impl(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
  % --- 1. Argument Validation ---
  if ~isvector(pn_range) || length(pn_range) != 2 || pn_range(1) > pn_range(2)
    error('pn_range must be a [min, max] vector.');
  endif
  if ~isvector(tn_range) || length(tn_range) != 2 || tn_range(1) > tn_range(2)
    error('tn_range must be a [min, max] vector.');
  endif
  if ~isvector(states_bins) || ~issorted(states_bins)
      error('states_bins must be a sorted vector of bin boundaries.');
  endif
  if ~isscalar(spns_per_bin) || spns_per_bin < 1
      error('spns_per_bin must be a positive integer.');
  endif
  if ~ischar(output_dir)
      error('output_dir must be a string.');
  endif

  % --- 2. Initialization ---
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  disp('Starting SPN dataset generation...');

  pn_values = pn_range(1):pn_range(2);
  tn_values = tn_range(1):tn_range(2);
  num_state_bins = length(states_bins) + 1;

  try
    bin_counts = containers.Map();
  catch ME
    if strcmp(ME.identifier, 'Octave:undefined-function')
      error(['`containers.Map` is not available. This is likely because the `struct` package is not loaded.\n' ...
             'Please run `pkg load struct` in your Octave session before calling this function.\n' ...
             'If the package is not installed, run `pkg install -forge struct` first.']);
    else
      rethrow(ME);
    endif
  end_try_catch

  total_bins = 0;
  for p = pn_values
      for t = tn_values
          for s_idx = 1:num_state_bins
              key = sprintf('p%d_t%d_s%d', p, t, s_idx);
              bin_counts(key) = 0;
              total_bins += 1;
          endfor
      endfor
  endfor

  total_spns_required = total_bins * spns_per_bin;
  total_spns_generated = 0;
  binned_spns = containers.Map();

  disp(['Target: ' num2str(spns_per_bin) ' SPNs for each of the ' num2str(total_bins) ' bins.']);
  disp(['Total SPNs to generate: ' num2str(total_spns_required)]);

  % --- 3. Main Generation Loop ---
  while total_spns_generated < total_spns_required
      pn = randi(pn_range);
      tn = randi(tn_range);
      prob = 0.5;
      max_lambda = 10;
      [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);
      filter_result = filter_spn(cm);

      if filter_result.valid
          num_states = columns(filter_result.reachability_graph_vertices);
          s_idx = get_state_bin_index(num_states, states_bins);
          bin_key = sprintf('p%d_t%d_s%d', pn, tn, s_idx);

          if isKey(bin_counts, bin_key) && bin_counts(bin_key) < spns_per_bin
              bin_counts(bin_key) += 1;
              total_spns_generated += 1;

              % Add the generated SPN to the in-memory bin.
              if ~isKey(binned_spns, bin_key)
                  binned_spns(bin_key) = {};
              endif
              current_bin_spns = binned_spns(bin_key);
              current_bin_spns{end+1} = filter_result;
              binned_spns(bin_key) = current_bin_spns;

              progress_percent = (total_spns_generated / total_spns_required) * 100;
              disp(sprintf('Progress: %.2f%% (%d / %d) - Found SPN for bin (p=%d, t=%d, s_idx=%d). Bin count: %d/%d', ...
                  progress_percent, total_spns_generated, total_spns_required, ...
                  pn, tn, s_idx, bin_counts(bin_key), spns_per_bin));
          endif
      endif
  endwhile

  % --- 4. Save Bins to HDF5 and Create Metadata ---
  disp('Saving binned SPNs to HDF5 files...');
  metadata = {};

  bin_keys = keys(binned_spns);
  for i = 1:length(bin_keys)
      bin_key = bin_keys{i};
      spn_results = binned_spns(bin_key);
      num_spns_in_bin = length(spn_results);

      % Define filename for the bin.
      bin_filename = [bin_key '.h5'];
      bin_filepath = fullfile(output_dir, bin_filename);

      if exist(bin_filepath, 'file')
          delete(bin_filepath);
      endif

      % --- Aggregate fixed-size data ---
      first_spn = spn_results{1};
      [pn, tn_x2] = size(first_spn.petri_net);
      tn = (tn_x2 - 1) / 2;

      % Pre-allocate arrays for stacking.
      stacked_petri_nets = zeros(pn, tn_x2, num_spns_in_bin);
      stacked_lambdas = zeros(tn, num_spns_in_bin);
      stacked_mus = zeros(1, num_spns_in_bin);

      for j = 1:num_spns_in_bin
          spn = spn_results{j};
          stacked_petri_nets(:, :, j) = spn.petri_net;
          stacked_lambdas(:, j) = spn.spn_lambda;
          stacked_mus(j) = spn.spn_mu;
      endfor

      % --- Write stacked data to HDF5 ---
      h5create(bin_filepath, '/stacked/petri_nets', size(stacked_petri_nets), 'Datatype', 'double');
      h5write(bin_filepath, '/stacked/petri_nets', stacked_petri_nets);

      h5create(bin_filepath, '/stacked/lambdas', size(stacked_lambdas), 'Datatype', 'double');
      h5write(bin_filepath, '/stacked/lambdas', stacked_lambdas);

      h5create(bin_filepath, '/stacked/mus', size(stacked_mus), 'Datatype', 'double');
      h5write(bin_filepath, '/stacked/mus', stacked_mus);

      % --- Write variable-size data and collect metadata ---
      for j = 1:num_spns_in_bin
          spn = spn_results{j};
          spn_group = sprintf('/spn_%d/', j);

          % Collect metadata for this SPN.
          num_states = columns(spn.reachability_graph_vertices);
          metadata{end+1} = {bin_filename, j, pn, tn, num_states};

          % Define datasets for variable-size data.
          datasets = {
              'rg_vertices', spn.reachability_graph_vertices;
              'rg_edges', spn.reachability_graph_edges;
              'arc_transitions', spn.arc_transitions_list;
              'mark_density', spn.spn_mark_density;
              'all_mus', spn.spn_all_mus
          };

          for k = 1:size(datasets, 1)
              dataset_name = datasets{k, 1};
              data = datasets{k, 2};

              if ~isempty(data)
                  h5_path = [spn_group dataset_name];
                  h5create(bin_filepath, h5_path, size(data), 'Datatype', 'double');
                  h5write(bin_filepath, h5_path, data);
              endif
          endfor
      endfor

      disp(['Saved bin ' bin_key ' to ' bin_filename]);
  endfor

  % --- Save Metadata ---
  disp('Saving metadata...');
  metadata_filepath = fullfile(output_dir, 'metadata.csv');
  fid = fopen(metadata_filepath, 'w');
  fprintf(fid, 'filename,index_in_file,places,transitions,states\n');
  for i = 1:length(metadata)
      fprintf(fid, '%s,%d,%d,%d,%d\n', metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, metadata{i}{4}, metadata{i}{5});
  endfor
  fclose(fid);

  disp('Dataset generation complete.');
endfunction

% --- Helper function for binning --------------------------------------------
function s_idx = get_state_bin_index(num_states, states_bins)
    s_idx = find(num_states < states_bins, 1);
    if isempty(s_idx)
        s_idx = length(states_bins) + 1;
    endif
endfunction
