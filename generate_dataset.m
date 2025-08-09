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
  % Continue until the required number of SPNs have been generated.
  while total_spns_generated < total_spns_required
      % Randomly select parameters for this iteration.
      pn = randi(pn_range);
      tn = randi(tn_range);

      % Generate a random SPN. Using default values for prob and max_lambda.
      % These could be exposed as arguments in a future version.
      prob = 0.5;
      max_lambda = 10;
      [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);

      % Run the filter and analysis.
      % Using default values for the filter limits.
      filter_result = filter_spn(cm);

      % Check if the generated SPN is valid.
      if filter_result.valid
          num_states = columns(filter_result.reachability_graph_vertices);
          s_idx = get_state_bin_index(num_states, states_bins);

          % Construct the key for the bin this SPN belongs to.
          bin_key = sprintf('p%d_t%d_s%d', pn, tn, s_idx);

          % Check if this bin is already full.
          if isKey(bin_counts, bin_key) && bin_counts(bin_key) < spns_per_bin
              % This is a useful SPN that fits into a bin we need.

              % Increment counts.
              bin_counts(bin_key) += 1;
              total_spns_generated += 1;

              % Save the valid SPN data to its own HDF5 file.
              filename = sprintf('spn_%d.h5', total_spns_generated);
              filepath = fullfile(output_dir, filename);

              % The '-hdf5' flag specifies the format. The 'filter_result' struct
              % containing all the SPN's data is saved.
              save('-hdf5', filepath, 'filter_result');

              % Add the details of this SPN to our metadata list.
              metadata{end+1} = {filename, pn, tn, num_states};

              % Report progress to the console.
              progress_percent = (total_spns_generated / total_spns_required) * 100;
              disp(sprintf('Progress: %.2f%% (%d / %d) - Found SPN for bin (p=%d, t=%d, s_idx=%d). Bin count: %d/%d', ...
                  progress_percent, total_spns_generated, total_spns_required, ...
                  pn, tn, s_idx, bin_counts(bin_key), spns_per_bin));
          endif
      endif
  endwhile

  % --- 4. Save Metadata ---
  disp('Saving metadata...');
  metadata_filepath = fullfile(output_dir, 'metadata.csv');
  fid = fopen(metadata_filepath, 'w');
  % Write header
  fprintf(fid, 'filename,places,transitions,states\n');
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
