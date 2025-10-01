%% benchmark_solvers(target_states, iterative_solvers, output_dir)
%%
%% Benchmarks the performance of exact vs. a list of iterative solvers.
%%
%% This script provides a flexible framework for comparing solver performance.
%% It takes a user-defined list of target state counts and a list of iterative
%% solvers to test.
%%
%% Key Features:
%% - Dynamic SPN Generation: Generates and saves SPNs to match the specified
%%   target state counts if they don't already exist.
%% - Multi-Solver Comparison: Benchmarks the exact solver against multiple
%%   iterative solvers in a single run.
%% - Comprehensive Output: The results are presented in multiple formats:
%%   - A dynamic summary table printed to the console.
%%   - A detailed CSV file.
%%   - A grouped bar chart comparing all solvers, saved as a PNG file.
%%
%% Inputs:
%%   target_states: A vector of target state counts for SPN generation
%%                  (e.g., [100, 500, 2000]).
%%
%%   iterative_solvers: A cell array of strings with the names of the
%%                      iterative solvers to test (e.g., {'gmres', 'bicg'}).
%%                      Run the `list_solvers` script to see recommended options.
%%
%%   output_dir: (Optional) A string specifying the path for storing SPNs
%%               and results. Default: 'benchmark_results'.
%%
%% Example Usage:
%%   benchmark_solvers([100, 500], {'gmres', 'bicg'});

function benchmark_solvers(target_states, iterative_solvers, output_dir = 'benchmark_results')
  % --- 1. Argument Validation ---
  if nargin < 2
    error("Usage: benchmark_solvers(target_states, iterative_solvers, [output_dir])");
  endif
  if ~isvector(target_states) || ~isnumeric(target_states)
    error('target_states must be a numeric vector.');
  endif
  if ~iscell(iterative_solvers)
    error('iterative_solvers must be a cell array of strings.');
  endif

  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  endif

  all_results = {};

  % --- 2. Main Benchmarking Loop ---
  disp('Starting flexible solver benchmark...');
  for i = 1:length(target_states)
    current_target = target_states(i);
    set_name = sprintf('states_%d', current_target);

    disp(['--- Processing target: ' set_name ' ---']);

    % --- 2a. Load or Generate SPN ---
    spn_filepath = fullfile(output_dir, sprintf('spn_%s.txt', set_name));
    if exist(spn_filepath, 'file')
      disp(['Loading existing SPN from: ' spn_filepath]);
      petri_net = load('-ascii', spn_filepath);
    else
      disp('No existing SPN found. Generating a new one...');
      petri_net = generate_spn_for_target_states(current_target, spn_filepath);
    endif

    if isempty(petri_net)
      warning('Failed to load or generate SPN for target: %s. Skipping.', set_name);
      continue;
    endif

    % --- 2b. Run Solvers and Collect Data ---
    num_transitions = (columns(petri_net) - 1) / 2;
    reachability_info = get_reachability_graph(petri_net);
    if ~reachability_info.bounded
        warning('SPN for %s is unbounded. Skipping.', set_name);
        continue;
    endif

    num_states = columns(reachability_info.v_list);

    % Benchmark Exact Solver (once per SPN)
    tic;
    [exact_ss, ~, ~, ~] = generate_steady_state_info(reachability_info, num_transitions, 'exact');
    time_exact = toc;

    if isempty(exact_ss)
        warning('Exact solver failed for %s. Skipping.', set_name);
        continue;
    endif

    % Store results for this SPN, starting with exact solver info
    current_spn_results = {set_name, num_states, time_exact};

    % Benchmark each iterative solver
    for j = 1:length(iterative_solvers)
        solver_name = iterative_solvers{j};
        tic;
        [iterative_ss, ~, ~, ~] = generate_steady_state_info(reachability_info, num_transitions, solver_name);
        time_iterative = toc;

        if ~isempty(iterative_ss)
          precision_loss = norm(exact_ss - iterative_ss);
        else
          precision_loss = NaN;
          time_iterative = NaN;
        endif

        current_spn_results{end+1} = time_iterative;
        current_spn_results{end+1} = precision_loss;
        disp(sprintf('  -> Solver: %-10s | Time: %.4fs, Loss: %.4e', solver_name, time_iterative, precision_loss));
    endfor

    all_results{end+1} = current_spn_results;
  endfor

  % --- 3. Output and Visualization ---
  if isempty(all_results)
    disp('No results to report.');
    return;
  endif

  print_summary_table(all_results, iterative_solvers);

  csv_filepath = fullfile(output_dir, 'benchmark_results.csv');
  save_results_to_csv(all_results, iterative_solvers, csv_filepath);

  plot_filepath = fullfile(output_dir, 'benchmark_plot.png');
  generate_and_save_plot(all_results, iterative_solvers, plot_filepath);

  disp('Benchmark complete.');
endfunction

% --- Helper function to generate an SPN for a target state count ---
function petri_net = generate_spn_for_target_states(target_states, filepath)
  petri_net = [];

  % --- 1. Define a dynamic search space based on target_states ---
  % Use a scaling factor to adjust parameters for larger state spaces.
  scaling_factor = sqrt(target_states / 100);

  pn_range = round([8, 12] * scaling_factor);
  tn_range = round([6, 10] * scaling_factor);

  % Increase connection density for more complex models
  prob = min(0.7, 0.5 + 0.1 * log(scaling_factor + 1));

  max_attempts = round(2000 * scaling_factor);

  disp(sprintf('  Generation parameters: pn=[%d,%d], tn=[%d,%d], prob=%.2f, max_attempts=%d', ...
    pn_range(1), pn_range(2), tn_range(1), tn_range(2), prob, max_attempts));

  found = false;
  attempts = 0;

  % --- 2. Iteratively search for a suitable SPN ---
  while ~found && attempts < max_attempts
    attempts += 1;
    pn = randi(pn_range);
    tn = randi(tn_range);
    [cm, ~] = spn_generate_random(pn, tn, prob, 10);

    if ~has_no_isolated_nodes(cm)
      cm = add_edges_to_isolated_nodes(cm);
    endif

    % Use a generous upper limit for the reachability graph exploration
    filter_result = filter_spn(cm, 10, 4, target_states * 4, 'exact');

    if filter_result.valid
      num_states = columns(filter_result.reachability_graph_vertices);
      % Accept if the number of states is reasonably close to the target
      if num_states > (target_states / 2) && num_states < (target_states * 2.5)
        found = true;
        petri_net = filter_result.petri_net;
        save('-ascii', filepath, 'petri_net');
        disp(sprintf('  -> Generated and saved SPN (p=%d, t=%d, states=%d) to %s', ...
          pn, tn, num_states, filepath));
      endif
    endif

    if mod(attempts, 500) == 0
      disp(['  ... generation attempt ' num2str(attempts)]);
    endif
  endwhile

  if ~found
    warning('Could not generate a suitable SPN for target_states ~%d after %d attempts.', target_states, max_attempts);
  endif
endfunction

% --- Reporting functions ---
function print_summary_table(results, iterative_solvers)
  fprintf('\n--- Benchmark Summary ---\n');

  % Build header dynamically
  header = '%-15s | %-12s | %-12s';
  header_titles = {'Category', 'Num States', 'Exact Time'};
  for i = 1:length(iterative_solvers)
    solver_name = upper(iterative_solvers{i});
    header = [header ' | %-12s | %-15s'];
    header_titles{end+1} = [solver_name ' Time'];
    header_titles{end+1} = [solver_name ' Loss'];
  endfor
  header = [header '\n'];

  fprintf(header, header_titles{:});
  fprintf([repmat('-', 1, 15) ' | ' repmat('-', 1, 12) ' | ' repmat('-', 1, 12)]);
  for i = 1:length(iterative_solvers)
      fprintf([' | ' repmat('-', 1, 12) ' | ' repmat('-', 1, 15)]);
  endfor
  fprintf('\n');

  % Build format string for data rows
  row_format = '%-15s | %-12d | %-12.4f';
  for i = 1:length(iterative_solvers)
    row_format = [row_format ' | %-12.4f | %-15.4e'];
  endfor
  row_format = [row_format '\n'];

  % Print data
  for i = 1:length(results)
    fprintf(row_format, results{i}{:});
  endfor

  fprintf([repmat('-', 1, 15) ' | ' repmat('-', 1, 12) ' | ' repmat('-', 1, 12)]);
  for i = 1:length(iterative_solvers)
      fprintf([' | ' repmat('-', 1, 12) ' | ' repmat('-', 1, 15)]);
  endfor
  fprintf('\n');
endfunction

function save_results_to_csv(results, iterative_solvers, filepath)
  fid = fopen(filepath, 'w');

  % Build header
  header = 'Category,Num_States,Exact_Time_s';
  for i = 1:length(iterative_solvers)
    solver_name = upper(iterative_solvers{i});
    header = [header sprintf(',%s_Time_s,%s_Precision_Loss', solver_name, solver_name)];
  endfor
  fprintf(fid, '%s\n', header);

  % Build format string
  row_format = '%s,%d,%.6f';
  for i = 1:length(iterative_solvers)
    row_format = [row_format ',%.6f,%.6e'];
  endfor
  row_format = [row_format '\n'];

  % Write data
  for i = 1:length(results)
    fprintf(fid, row_format, results{i}{:});
  endfor

  fclose(fid);
  disp(['Detailed results saved to: ' filepath]);
endfunction

function generate_and_save_plot(results, iterative_solvers, filepath)
  num_targets = length(results);
  num_iterative = length(iterative_solvers);

  categories = cellfun(@(c) strrep(c{1}, '_', ' '), results, 'UniformOutput', false);

  % Extract times for all solvers
  times_exact = cellfun(@(c) c{3}, results);
  times_iterative = zeros(num_targets, num_iterative);
  for i = 1:num_targets
      for j = 1:num_iterative
          times_iterative(i, j) = results{i}{3 + 2*(j-1) + 1};
      end
  end

  bar_data = [times_exact', times_iterative];

  h = figure('Visible', 'off');
  bar(bar_data, 'grouped');

  set(gca, 'XTickLabel', categories);
  title('Solver Performance Benchmark');
  xlabel('SPN Target Complexity');
  ylabel('Execution Time (seconds)');
  legend_names = [{'Exact'}, cellfun(@upper, iterative_solvers, 'UniformOutput', false)];
  legend(legend_names, 'Location', 'northwest');
  grid on;

  % Use a log scale for the y-axis if times are very different
  if any(bar_data(:)) && max(bar_data(:)) / min(bar_data(bar_data(:)>0)) > 100
      set(gca, 'YScale', 'log');
      ylabel('Execution Time (seconds, log scale)');
  endif

  saveas(h, filepath);
  disp(['Benchmark plot saved to: ' filepath]);
endfunction