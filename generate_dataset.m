%% generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
%%
%% Generates a dataset of Stochastic Petri Nets (SPNs) based on a grid
%% configuration and saves them to files.
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
%%   generate_dataset([5, 10], [4, 8], [20, 100], 5, 'spn_dataset');
%%   This will generate 5 SPNs for each bin defined by the combinations of
%%   places (5-10), transitions (4-8), and states (<20, 20-99, >=100).

function generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
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

  % --- 3. Main Generation Loop ---
  % Load the parallel package
  pkg load parallel;

  % Define batch size, e.g., based on the number of available cores.
  % We generate more SPNs than needed in each batch because many will be invalid.
  batch_size = nproc() * 5;
  disp(['Using batch size: ' num2str(batch_size)]);

  % This cell array will hold the final, valid SPNs before they are saved.
  valid_spns = {};

  % Continue until the required number of SPNs have been generated.
  while total_spns_generated < total_spns_required
    % Generate a batch of SPNs in parallel.
    batch_results = cell(1, batch_size);
    parfor i = 1:batch_size
        % Randomly select parameters for this iteration.
        pn = randi(pn_range);
        tn = randi(tn_range);

        % Generate a random SPN. Using default values.
        prob = 0.5;
        max_lambda = 10;
        [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);

        % Run the filter and analysis and store the result.
        batch_results{i} = filter_spn(cm);
    endparfor % End of parallel batch generation

    % --- Serial Processing of the Batch ---
    % Now, iterate through the generated batch and check which SPNs
    % can be added to our dataset.
    for i = 1:numel(batch_results)
      filter_result = batch_results{i};

      if !isstruct(filter_result) || !isfield(filter_result, 'valid')
        continue;
      endif

      if filter_result.valid
        % Derive pn and tn from the incidence matrix
        pn = rows(filter_result.petri_net);
        tn = (columns(filter_result.petri_net) - 1) / 2;

        num_states = columns(filter_result.reachability_graph_vertices);
        s_idx = get_state_bin_index(num_states, states_bins);

        % Construct the key for the bin this SPN belongs to.
        bin_key = sprintf('p%d_t%d_s%d', pn, tn, s_idx);

        % Check if this bin is defined and not yet full.
        if isKey(bin_counts, bin_key) && bin_counts(bin_key) < spns_per_bin
          % This is a useful SPN that fits into a bin we need.

          % Increment counts.
          bin_counts(bin_key) += 1;
          total_spns_generated += 1;

          % Add the SPN data to our master list for later saving.
          valid_spns{end+1} = filter_result;

          % The "filename" will now be a key in the consolidated HDF5 file.
          spn_key = sprintf('spn_%d', total_spns_generated);

          % Add the details of this SPN to our metadata list.
          metadata{end+1} = {spn_key, pn, tn, num_states};

          % Report progress to the console.
          progress_percent = (total_spns_generated / total_spns_required) * 100;
          disp(sprintf('Progress: %.2f%% (%d / %d) - Found SPN for bin (p=%d, t=%d, s_idx=%d). Bin count: %d/%d', ...
              progress_percent, total_spns_generated, total_spns_required, ...
              pn, tn, s_idx, bin_counts(bin_key), spns_per_bin));
        endif
      endif

      % If we've collected enough SPNs, we can stop processing this batch.
      if total_spns_generated >= total_spns_required
        break; % Exit the serial processing loop
      endif
    endfor
  endwhile

  % --- 4. Save Consolidated Dataset and Metadata ---
  disp('Consolidating generated SPNs for saving...');

  % Create a single struct where each field is a valid SPN.
  % The field name will be the key (e.g., 'spn_1').
  all_spns_struct = struct();
  for i = 1:length(valid_spns)
      spn_key = metadata{i}{1};
      all_spns_struct.(spn_key) = valid_spns{i};
  endfor

  % Save the consolidated struct to a single HDF5 file.
  % The '-struct' option saves each field as a separate dataset.
  disp('Saving SPN data to consolidated HDF5 file...');
  h5_filepath = fullfile(output_dir, 'spn_dataset.h5');
  if exist(h5_filepath, 'file')
    delete(h5_filepath); % Ensure we start with a fresh file
  endif
  save('-hdf5', h5_filepath, '-struct', 'all_spns_struct');

  % --- Save Metadata to CSV ---
  disp('Saving metadata...');
  metadata_filepath = fullfile(output_dir, 'metadata.csv');
  fid = fopen(metadata_filepath, 'w');
  % Write header
  fprintf(fid, 'spn_key,places,transitions,states\n'); % Changed 'filename' to 'spn_key'
  % Write data rows
  for i = 1:length(metadata)
      fprintf(fid, '%s,%d,%d,%d\n', metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, metadata{i}{4});
  endfor
  fclose(fid);

  disp('Dataset generation complete.');
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
