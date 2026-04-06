%% bench_solving.m
%% Benchmarks the solving phase on an existing SPN to avoid generation issues.
target_states = 100;
iterative_solvers = {'bicg'};

disp('Benchmarking solving phase using a pre-generated SPN...');
% Just load an existing one or create a very simple deterministic one
T_in = [1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0; 0, 0, 0, 1; 1, 0, 0, 0];
T_out = [0, 1, 0, 0; 0, 0, 1, 0; 0, 0, 0, 1; 1, 0, 0, 0; 0, 1, 0, 0];
M0 = [1; 0; 0; 0; 0];
cm = [T_in, T_out, M0];

% The function benchmark_solvers actually generates SPNs dynamically if it doesn't find one in the output_dir.
% Let's write the generated CM to `benchmark_results/spn_states_100.txt` so it finds it.
mkdir('benchmark_results');
save('-ascii', 'benchmark_results/spn_states_100.txt', 'cm');

benchmark_solvers([target_states], iterative_solvers);
