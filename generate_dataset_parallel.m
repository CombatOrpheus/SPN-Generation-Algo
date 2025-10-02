%% generate_dataset_parallel(pn_range, tn_range, states_bins, spns_per_bin, output_dir, varargin)
%%
%% Generates a comprehensive dataset of Stochastic Petri Nets (SPNs) in parallel.
%%
%% This script uses the `parallel` package to accelerate dataset generation by
%% processing multiple SPN candidates simultaneously across multiple CPU cores.
%% It relies on a helper function, `generate_and_filter_spn`, to perform the
%% core generation and validation logic for each SPN.
%%
%% The script processes SPNs in batches, collects the valid ones, and saves them
%% into the appropriate bins until the desired number of SPNs for each bin is
-%% reached.
%%
%% Requirements:
%%   - Octave `parallel` package must be installed (`pkg install -forge parallel`).
%%
%% Inputs:
%%   pn_range: A 1x2 vector `[min, max]` for the number of places.
%%
%%   tn_range: A 1x2 vector `[min, max]` for the number of transitions.
%%
%%   states_bins: A sorted vector defining state-based bin boundaries.
%%
%%   spns_per_bin: The target number of valid SPNs for each bin.
%%
%%   output_dir: A string specifying the path to the output directory.
%%
%%   varargin: (Optional) A list of key-value pairs for additional options.
%%     'solver': A string specifying the solver for steady-state analysis.
%%               Can be 'exact' (default) or an iterative solver like 'gmres'.
%%
%% Example Usage:
%%   % Generate a dataset using 4 cores.
%%   generate_dataset_parallel([5, 10], [4, 8], [20, 100], 5, 'my_spn_dataset_parallel');

function generate_dataset_parallel(pn_range, tn_range, states_bins, spns_per_bin, output_dir, varargin)
  % --- 1. Argument Parsing and Validation ---
  % Default values
  solver = 'exact';

  % Process optional arguments
  i = 1;
  while i <= length(varargin)
    if strcmp(varargin{i}, 'solver')
      solver = varargin{i+1};
      i += 2;
    else
      error('Unknown option: %s', varargin{i});
    endif
  endwhile

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
  pkg load parallel;

  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  disp(['Starting SPN dataset generation in parallel with solver: ' solver]);

  pn_values = pn_range(1):pn_range(2);
  tn_values = tn_range(1):tn_range(2);
  num_state_bins = length(states_bins) + 1;

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
  ncores = nproc();
  batch_size = ncores * 4; % Process a batch of SPNs per iteration

  disp(['Using ' num2str(ncores) ' cores to generate ' num2str(total_spns_required) ' total SPNs.']);

  % --- 3. Main Parallel Generation Loop ---
  while total_spns_generated < total_spns_required
    disp(['Generating a batch of ' num2str(batch_size) ' SPNs...']);

    % Use pararrayfun to generate and filter SPNs in parallel
    results = pararrayfun(ncores, ...
      @(i) generate_and_filter_spn(i, pn_range, tn_range, solver), ...
      1:batch_size, "UniformOutput", false);

    % Process the results from the parallel batch
    for i = 1:length(results)
      filter_result = results{i};

      if isstruct(filter_result) && isfield(filter_result, 'valid') && filter_result.valid
        num_states = columns(filter_result.reachability_graph_vertices);
        s_idx = get_state_bin_index(num_states, states_bins);
        pn = filter_result.pn;
        tn = filter_result.tn;

        bin_key = sprintf('p%d_t%d_s%d', pn, tn, s_idx);

        if isKey(bin_counts, bin_key) && bin_counts(bin_key) < spns_per_bin
          bin_counts(bin_key) += 1;
          total_spns_generated += 1;

          filename = sprintf('spn_%d.h5', total_spns_generated);
          filepath = fullfile(output_dir, filename);
          save('-hdf5', filepath, 'filter_result');

          metadata{end+1} = {filename, pn, tn, num_states};

          progress_percent = (total_spns_generated / total_spns_required) * 100;
          disp(sprintf('Progress: %.2f%% (%d / %d) - Found SPN for bin (p=%d, t=%d, s_idx=%d). Bin count: %d/%d', ...
              progress_percent, total_spns_generated, total_spns_required, ...
              pn, tn, s_idx, bin_counts(bin_key), spns_per_bin));
        endif
      endif

      % Early exit if all required SPNs have been found
      if total_spns_generated >= total_spns_required
        break;
      endif
    endfor
  endwhile

  % --- 4. Save Metadata ---
  disp('Saving metadata...');
  metadata_filepath = fullfile(output_dir, 'metadata.csv');
  fid = fopen(metadata_filepath, 'w');
  fprintf(fid, 'filename,places,transitions,states\n');
  for i = 1:length(metadata)
      fprintf(fid, '%s,%d,%d,%d\n', metadata{i}{1}, metadata{i}{2}, metadata{i}{3}, metadata{i}{4});
  endfor
  fclose(fid);

  disp('Parallel dataset generation complete.');
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