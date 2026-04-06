%% bench_generation.m
%% Benchmarks the generation phase.
num_spns = 100;
pn_range = [10, 15];
tn_range = [10, 15];
prob = 0.5;
max_lambda = 10;

disp(['Benchmarking generation of ', num2str(num_spns), ' SPNs...']);
tic;
for i = 1:num_spns
  pn = randi(pn_range);
  tn = randi(tn_range);
  [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda);
end
elapsed = toc;
disp(['Generation phase took: ', num2str(elapsed), ' seconds.']);
