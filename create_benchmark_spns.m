%% create_benchmark_spns(output_dir)
%%
%% Generates and saves a robust collection of SPNs for benchmarking.
%%
%% This script creates a standardized set of SPNs of varying complexity
%% (small, medium, large, huge) for consistent performance evaluation.
%%
%% To ensure the generation of valid, complex SPNs, this script employs an
%% aggressive, targeted strategy. For larger models, it increases the number
%% of generation attempts and adjusts the connection density (`prob`) to
%% increase the likelihood of finding a solvable SPN. It also explicitly
%% corrects disconnected nodes before running the full `filter_spn` analysis.
%%
%% The resulting SPN matrices are saved to individual text files.
%%
%% Inputs:
%%   output_dir: A string specifying the path to the directory where the
%%               benchmark SPN files will be saved.
%%
%% Example Usage:
%%   create_benchmark_spns('benchmark_spns');

function create_benchmark_spns(output_dir)
  % --- 1. Initialization ---
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  disp('Starting generation of benchmark SPNs...');

  % Define the parameters for each size category.
  % Format: {name, pn_range, tn_range, target_states, prob, max_attempts}
  benchmark_sets = {
    {'small',  [10, 15],  [8, 12],   100,   0.5, 2000},
    {'medium', [15, 20],  [12, 18],  500,   0.5, 5000},
    {'large',  [25, 35],  [20, 30],  2000,  0.6, 15000},
    {'huge',   [40, 50],  [35, 45],  5000,  0.7, 30000}
  };

  % --- 2. Generation Loop ---
  for i = 1:length(benchmark_sets)
    set_name = benchmark_sets{i}{1};
    pn_range = benchmark_sets{i}{2};
    tn_range = benchmark_sets{i}{3};
    target_states = benchmark_sets{i}{4};
    prob = benchmark_sets{i}{5};
    max_attempts = benchmark_sets{i}{6};

    disp(sprintf('Generating SPN for category: %s (target_states=~%d, prob=%.1f, max_attempts=%d)', ...
      set_name, target_states, prob, max_attempts));

    found = false;
    attempts = 0;
    mini_batch_size = 20; % Generate in batches to speed up search

    while ~found && attempts < max_attempts
      % Generate a batch of random SPNs
      pn = randi(pn_range);
      tn = randi(tn_range);
      [cms, ~] = spn_generate_random(pn, tn, prob, 10, mini_batch_size);

      % Process the batch
      for k = 1:mini_batch_size
        attempts += 1;
        if attempts >= max_attempts
          break;
        endif

        cm = cms(:, :, k);

        % --- Robustness Step: Ensure Connectivity ---
        if ~has_no_isolated_nodes(cm)
          cm = add_edges_to_isolated_nodes(cm);
        endif

        % Now, filter the (potentially corrected) SPN.
        filter_result = filter_spn(cm, 10, 4, target_states * 2, 'exact');

        if filter_result.valid
          num_states = columns(filter_result.reachability_graph_vertices);
          % Check if the SPN is non-trivial and within our desired complexity.
          if num_states > (target_states / 5) && num_states < (target_states * 1.5)
            found = true;

            % Save the valid SPN matrix to a text file.
            petri_net_to_save = filter_result.petri_net;
            filename = sprintf('spn_%s.txt', set_name);
            filepath = fullfile(output_dir, filename);
            save('-ascii', filepath, 'petri_net_to_save');

            disp(sprintf('  -> Found and saved %s SPN (p=%d, t=%d, states=%d) to %s', ...
              set_name, pn, tn, num_states, filepath));
            break; % Exit the inner for-loop
          endif
        endif

        if mod(attempts, 500) == 0
          disp(['  ... attempt ' num2str(attempts)]);
        endif
      endfor
    endwhile

    if ~found
      warning('Could not generate a suitable SPN for category: %s after %d attempts.', set_name, max_attempts);
    endif
  endfor

  disp('Benchmark SPN generation complete.');
endfunction