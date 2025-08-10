%% generate_dataset_parallel(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
%%
%% Generates a dataset of Stochastic Petri Nets (SPNs) based on a grid
%% configuration and saves them to files. This version is parallelized.
%%
%% This script systematically generates and validates SPNs, binning them based
%% on their structural properties (number of places, transitions) and behavioral
%% properties (number of states in the reachability graph). It aims to create
%% a specified number of valid SPNs for each defined bin.
%%
%% Inputs:
%%   pn_range: A 1x2 vector [min, max] specifying the range for the number of places.
%%   tn_range: A 1x2 vector [min, max] specifying the range for the number of transitions.
%%   states_bins: A vector defining the upper boundaries for the state bins.
%%                For example, [10, 50, 100] creates four bins:
%%                <10, 10-49, 50-99, >=100 states.
%%   spns_per_bin: The target number of valid SPNs to generate for each bin.
%%   output_dir: A string specifying the path to the directory where the dataset
%%               (HDF5 files and metadata.csv) will be saved.
%%
%% Example Usage:
%%   generate_dataset_parallel([5, 10], [4, 8], [20, 100], 5, 'spn_dataset');
%%   This will generate 5 SPNs for each bin defined by the combinations of
%%   places (5-10), transitions (4-8), and states (<20, 20-99, >=100).

function generate_dataset_parallel(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
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
  % Create the output directory if it doesn't exist.
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  disp('Starting SPN dataset generation...');

  % Define the full set of bins to be filled.
  pn_values = pn_range(1):pn_range(2);
  tn_values = tn_range(1):tn_range(2);
  num_state_bins = length(states_bins) + 1;

  % Use a Map to store the counts for each bin. The key will be a string like
  % "p<pn>_t<tn>_s<s_idx>" to uniquely identify each bin.
  bin_counts = containers.Map();
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
  metadata = {}; % Initialize an empty cell array for metadata

  disp(['Target: ' num2str(spns_per_bin) ' SPNs for each of the ' num2str(total_bins) ' bins.']);
  disp(['Total SPNs to generate: ' num2str(total_spns_required)]);

  % --- 3. Parallel Generation Loop ---
  pkg load parallel;
  num_cores = nproc; % Get number of available cores

  temp_dir = fullfile(output_dir, 'temp_spns');
  if ~exist(temp_dir, 'dir')
    mkdir(temp_dir);
  endif

  all_valid_spns = {};

  while total_spns_generated < total_spns_required
      batch_size = max(num_cores, ceil((total_spns_required - total_spns_generated) * 1.2));
      disp(sprintf('Generating a batch of %d candidates in parallel...', batch_size));

      candidates = cell(1, batch_size);
      temp_filepaths = cell(1, batch_size);
      for i = 1:batch_size
          temp_filepaths{i} = tempname(temp_dir);
      endfor

      parfor i = 1:batch_size
          candidates{i} = generate_and_validate_spn(pn_range, tn_range, states_bins, temp_filepaths{i});
      endparfor

      disp(sprintf('Processing %d candidates...', length(candidates)));

      for i = 1:length(candidates)
          result = candidates{i};
          if result.valid && total_spns_generated < total_spns_required
              if isKey(bin_counts, result.bin_key) && bin_counts(result.bin_key) < spns_per_bin
                  bin_counts(result.bin_key) += 1;
                  total_spns_generated += 1;
                  all_valid_spns{end+1} = result;

                  progress_percent = (total_spns_generated / total_spns_required) * 100;
                  disp(sprintf('Progress: %.2f%% (%d / %d) - Found SPN for bin (p=%d, t=%d, s_idx=%d). Bin count: %d/%d', ...
                      progress_percent, total_spns_generated, total_spns_required, ...
                      result.pn, result.tn, result.s_idx, bin_counts(result.bin_key), spns_per_bin));
              else
                  % This SPN is valid, but its bin is already full. Delete temp file.
                  delete(result.filepath);
              endif
          elseif result.valid
              % This SPN is valid, but we have already generated enough. Delete temp file.
              delete(result.filepath);
          endif
      endfor
  endwhile

  % --- 4. Consolidate Files and Save Metadata ---
  disp('Consolidating files and saving metadata...');
  for i = 1:length(all_valid_spns)
      result = all_valid_spns{i};
      new_filename = sprintf('spn_%d.h5', i);
      new_filepath = fullfile(output_dir, new_filename);
      movefile(result.filepath, new_filepath);
      metadata{end+1} = {new_filename, result.pn, result.tn, result.num_states};
  endfor

  % Clean up the temporary directory
  rmdir(temp_dir, 's');

  metadata_filepath = fullfile(output_dir, 'metadata.csv');
  fid = fopen(metadata_filepath, 'w');
  fprintf(fid, 'filename,places,transitions,states\n');
  for i = 1:length(metadata)
      fprintf(fid, '%s,%d,%d,%d\n', metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, metadata{i}{4});
  endfor
  fclose(fid);

  disp('Dataset generation complete.');
endfunction


% --- Function to generate and validate a single SPN ---
function result = generate_and_validate_spn(pn_range, tn_range, states_bins, temp_filepath)
    result = struct(); % Initialize empty struct
    result.valid = false;

    % Randomly select parameters for this iteration.
    pn = randi(pn_range);
    tn = randi(tn_range);

    % Generate a random SPN.
    prob = 0.5;
    max_lambda = 10;
    [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);

    % Run the filter and analysis.
    filter_result = filter_spn(cm);

    % Check if the generated SPN is valid.
    if filter_result.valid
        num_states = columns(filter_result.reachability_graph_vertices);
        s_idx = get_state_bin_index(num_states, states_bins);
        bin_key = sprintf('p%d_t%d_s%d', pn, tn, s_idx);

        % Save to the provided temporary file path
        save('-hdf5', temp_filepath, 'filter_result');

        result.filepath = temp_filepath;
        result.pn = pn;
        result.tn = tn;
        result.num_states = num_states;
        result.s_idx = s_idx;
        result.bin_key = bin_key;
        result.valid = true;
    endif
endfunction


% --- Helper function for binning ---
function s_idx = get_state_bin_index(num_states, states_bins)
% Determines which state bin a given number of states falls into.
    s_idx = find(num_states < states_bins, 1);
    if isempty(s_idx)
        % If it's not smaller than any boundary, it belongs in the last bin.
        s_idx = length(states_bins) + 1;
    endif
endfunction
