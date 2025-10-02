%% generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir, varargin)
%%
%% Generates a comprehensive dataset of Stochastic Petri Nets (SPNs).
%%
%% This is the main script for creating a benchmark dataset. It systematically
%% generates and validates a large number of SPNs, binning them according to
%% their structural and behavioral properties.
%%
%% The script operates in a loop, generating random SPNs and then filtering them
%% using `filter_spn`. Only valid SPNs that fall into a bin that is not yet
%% full are saved. This process continues until the target number of SPNs for
%% each bin has been met.
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
%%     'mini_batch_size': An integer specifying how many SPNs to generate
%%                        and test in each batch. Default is 10.
%%
%% Example Usage:
%%   % Generate a dataset with default options.
%%   generate_dataset([5, 10], [4, 8], [20, 100], 5, 'my_spn_dataset');
%%
%%   % Generate a dataset with a custom solver and batch size.
%%   generate_dataset([5, 10], [4, 8], [20, 100], 5, 'my_spn_dataset', 'solver', 'gmres', 'mini_batch_size', 20);

function generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir, varargin)
  % --- 1. Argument Parsing and Validation ---
  % Default values
  solver = 'exact';
  mini_batch_size = 10; % Default batch size

  % Process optional arguments
  i = 1;
  while i <= length(varargin)
    if strcmp(varargin{i}, 'solver')
      solver = varargin{i+1};
      i += 2;
    elseif strcmp(varargin{i}, 'mini_batch_size')
      mini_batch_size = varargin{i+1};
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
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  disp(['Starting SPN dataset generation with solver: ' solver]);

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

  disp(['Target: ' num2str(spns_per_bin) ' SPNs for each of the ' num2str(total_bins) ' bins.']);
  disp(['Total SPNs to generate: ' num2str(total_spns_required)]);

  % --- 3. Main Generation Loop ---
  while total_spns_generated < total_spns_required
      pn = randi(pn_range);
      tn = randi(tn_range);

      prob = 0.5;
      max_lambda = 10;
      % Generate a batch of SPNs
      [cms, ~] = spn_generate_random(pn, tn, prob, max_lambda, mini_batch_size);

      % Process each SPN in the batch
      for k = 1:mini_batch_size
          cm = cms(:, :, k);
          % Run the filter and analysis, passing the chosen solver.
          filter_result = filter_spn(cm, 10, 4, 500, solver);

          if filter_result.valid
              num_states = columns(filter_result.reachability_graph_vertices);
              s_idx = get_state_bin_index(num_states, states_bins);

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

                  if total_spns_generated >= total_spns_required
                      break; % Exit the inner loop if all required SPNs are found
                  endif
              endif
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