%% bench_filtering.m
%% Benchmarks the filtering phase.
num_spns = 50;
pn_range = [8, 12];
tn_range = [8, 12];
prob = 0.5;
max_lambda = 10;

disp(['Benchmarking filtering of ', num2str(num_spns), ' generated SPNs...']);
% First generate some SPNs to filter (don't include generation time in filter benchmark)
spns = cell(num_spns, 1);
for i = 1:num_spns
  pn = randi(pn_range);
  tn = randi(tn_range);
  [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);
  spns{i} = cm;
end

disp('Starting filter benchmark...');
tic;
for i = 1:num_spns
  filter_result = filter_spn(spns{i}, 10, 4, 1000, 'exact');
end
elapsed = toc;
disp(['Filtering phase took: ', num2str(elapsed), ' seconds.']);
