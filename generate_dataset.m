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
  metadata = {};

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

% --- Helper function for binning --------------------------------------------
function s_idx = get_state_bin_index(num_states, states_bins)
    s_idx = find(num_states < states_bins, 1);
    if isempty(s_idx)
        s_idx = length(states_bins) + 1;
    endif
endfunction
