%% run_single_benchmark
%%
%% A wrapper script to run the solver benchmark for a single SPN category.
%%
%% This script is designed to address timeouts in environments with limited
%% execution time. It allows for the incremental generation of benchmark SPNs
%% by running the main `benchmark_solvers` script for one specific category
%% at a time.
%%
%% The script takes a single command-line argument: the name of the category
%% to run (e.g., 'small', 'medium', 'large', 'huge'). It then configures the
%% main benchmark script to only process that category.
%%
%% Usage:
%%   octave --eval "run_single_benchmark('large')"

function run_single_benchmark(category_name)
  % --- 1. Get Category from Command-Line Arguments ---
  if nargin < 1
    error("Usage: octave --eval \"run_single_benchmark('category_name')\"");
  endif

  % --- 2. Define Benchmark Parameters ---
  % These must match the parameters in `benchmark_solvers.m`
  all_params = {
    {'small',  [10, 15],  [8, 12],   100,   0.5, 2000},
    {'medium', [15, 20],  [12, 18],  500,   0.5, 5000},
    {'large',  [25, 35],  [20, 30],  2000,  0.6, 15000},
    {'huge',   [40, 50],  [35, 45],  5000,  0.7, 30000}
  };

  % --- 3. Find Parameters for the Target Category ---
  target_params = {};
  for i = 1:length(all_params)
    if strcmp(all_params{i}{1}, category_name)
      target_params = all_params{i};
      break;
    endif
  endfor

  if isempty(target_params)
    error('Unknown benchmark category: %s', category_name);
  endif

  % --- 4. Run the Benchmark for the Single Category ---
  disp(['--- Running benchmark for single category: ' category_name ' ---']);
  % The 'params' argument overrides the default loop and runs only this one.
  benchmark_solvers('benchmark_results', 'params', {target_params});

  disp(['--- Completed benchmark for single category: ' category_name ' ---']);
endfunction