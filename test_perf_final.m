pn_range = [2000, 2000];
tn_range = [2000, 2000];
prob = 0.001;
max_lambda = 10;
tic;
for i = 1:5
  [cm, lambda] = spn_generate_random(pn_range(1), tn_range(1), prob, max_lambda);
end
elapsed_gen = toc;

petri_net = [1, 0, 0, 0, 1; 0, 1, 0, 0, 0; 0, 0, 1, 0, 0; 0, 0, 0, 1, 0; 1, 0, 0, 0, 0];
tic;
for i = 1:50000
  del_edge(petri_net);
end
elapsed_del = toc;

tic;
for i = 1:50000
  add_edges_to_isolated_nodes(petri_net);
end
elapsed_add = toc;

disp(["spn_generate_random (5 large graphs): ", num2str(elapsed_gen), " seconds"]);
disp(["del_edge (50k iterations): ", num2str(elapsed_del), " seconds"]);
disp(["add_edges_to_isolated_nodes (50k iterations): ", num2str(elapsed_add), " seconds"]);
