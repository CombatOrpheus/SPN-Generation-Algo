% run_benchmarks.m - Benchmarking suite matching SPN-Algo-Go benchmarks

function run_benchmarks()
  ignore_function_time_stamp("all");
  addpath("benchmarks");
  printf("===================================================================\n");

  printf("  SPN-Algo-Octave Benchmarks (GNU Octave %s)\n", version());
  printf("===================================================================\n\n");

  % 1. Generation Small (5, 5)
  pn_gen_sm = generate_test_petrinet(5, 5);
  run_bench("BenchmarkGeneration_Small", @() generate_reachability_graph(pn_gen_sm, 10, 1000));

  % 2. Generation Medium (20, 20)
  pn_gen_med = generate_test_petrinet(20, 20);
  run_bench("BenchmarkGeneration_Medium", @() generate_reachability_graph(pn_gen_med, 10, 1000));

  % 3. Generation Large (50, 50)
  pn_gen_lg = generate_test_petrinet(50, 50);
  run_bench("BenchmarkGeneration_Large", @() generate_reachability_graph(pn_gen_lg, 10, 10000), 2, 1.0);

  % 4. Analysis Small (5, 5)
  pn_ana_sm = generate_test_petrinet(5, 5);
  rg_ana_sm = generate_reachability_graph(pn_ana_sm, 10, 1000);
  lambdas_sm = double(randi([1, 10], 5, 1));
  run_bench("BenchmarkAnalysis_Small", @() bench_analysis(rg_ana_sm, lambdas_sm));

  % 5. Analysis Medium (20, 20)
  pn_ana_med = generate_test_petrinet(20, 20);
  rg_ana_med = generate_reachability_graph(pn_ana_med, 10, 1000);
  lambdas_med = double(randi([1, 10], 20, 1));
  run_bench("BenchmarkAnalysis_Medium", @() bench_analysis(rg_ana_med, lambdas_med), 5, 1.0);

  % 6. Augmentation PetriNet Small (5, 5)
  pn_aug_sm = generate_test_petrinet(5, 5);
  run_bench("BenchmarkAugmentation_PetriNet_Small", @() generate_petrinet_variations(pn_aug_sm, 10, 1, 1000, 5, 1, 10));

  % 7. Augmentation PetriNet Medium (15, 15)
  pn_aug_med = generate_test_petrinet(15, 15);
  run_bench("BenchmarkAugmentation_PetriNet_Medium", @() generate_petrinet_variations(pn_aug_med, 10, 1, 1000, 5, 1, 10), 3, 1.0);

  % 8. Augmentation Lambda Medium (20, 20)
  pn_aug_lmed = generate_test_petrinet(20, 20);
  rg_aug_lmed = generate_reachability_graph(pn_aug_lmed, 10, 1000);
  run_bench("BenchmarkAugmentation_Lambda_Medium", @() generate_lambda_variations(pn_aug_lmed, rg_aug_lmed, 5, 1, 10), 2, 1.0);

  % 9. WholeProgram Pipeline
  run_bench("BenchmarkWholeProgram_Pipeline", @() bench_pipeline(), 5, 1.0);

  printf("\n-------------------------------------------------------------------\n");
  printf("  Dedicated Individual Improvement Microbenchmarks\n");
  printf("-------------------------------------------------------------------\n\n");

  % I. Solver: Direct LU vs Sparse Uniformization (Power Iteration)
  [sm_med, tv_med] = compute_state_equation(rg_ana_med, lambdas_med);
  run_bench("Improvement_Solver_DirectLU", @() solve_steady_state(sm_med, tv_med), 5, 1.0);
  run_bench("Improvement_Solver_Iterative", @() solve_steady_state_iterative(rg_ana_med, lambdas_med), 5, 1.0);

  % II. Average Markings: repmat vs repelem
  probs_med = solve_steady_state_iterative(rg_ana_med, lambdas_med);
  run_bench("Improvement_AvgMarkings_Repmat", @() bench_avg_markings_repmat(rg_ana_med, probs_med), 10, 1.0);
  run_bench("Improvement_AvgMarkings_Repelem", @() compute_average_markings(rg_ana_med, probs_med), 10, 1.0);

  % III. Connectivity: Degree-only vs Bipartite BFS
  pn_dense = petrinet_new(20, 20);
  pn_dense.matrix(:, 1:40) = int32(rand(20, 40) > 0.5);
  run_bench("Improvement_Connect_DegreeOnly", @() bench_degree_check(pn_dense), 20, 1.0);
  run_bench("Improvement_Connect_BipartiteBFS", @() petrinet_is_connected(pn_dense), 20, 1.0);

  % IV. Pruning: Pure Octave vs C++ Oct-file
  run_bench("Improvement_Prune_PureOctave", @() petrinet_prune(pn_dense, true), 5, 1.0);
  run_bench("Improvement_Prune_CPPOct", @() petrinet_prune(pn_dense, false), 5, 1.0);

  % V. Reachability Graph: Pure Octave vs C++ Oct-file
  run_bench("Improvement_Reachability_PureOctave", @() generate_reachability_graph(pn_gen_sm, 10, 1000, true), 5, 1.0);
  run_bench("Improvement_Reachability_CPPOct", @() generate_reachability_graph(pn_gen_sm, 10, 1000, false), 5, 1.0);

  % VI. Parallel Multiprocessing Generation: Sequential vs Multi-core
  cfg_bpar = struct();
  cfg_bpar.generation_mode = "random";
  cfg_bpar.num_places = 5;
  cfg_bpar.num_transitions = 3;
  cfg_bpar.num_samples = 30;
  cfg_bpar.exact_samples = true;
  cfg_bpar.place_upper_bound = 10;
  cfg_bpar.marks_lower_limit = 2;
  cfg_bpar.marks_upper_limit = 200;
  cfg_bpar.min_firing_rate = 1;
  cfg_bpar.max_firing_rate = 5;
  cfg_bpar.enable_transformations = false;
  cfg_bpar.enable_statistics_report = false;
  cfg_bpar.quiet = true;
  tmp_bpar = fullfile(tempdir(), "bench_parallel_out.jsonl");

  run_bench("Improvement_Parallel_1_Worker", @() generate_parallel_dataset(cfg_bpar, 1, tmp_bpar), 3, 1.0);
  run_bench("Improvement_Parallel_4_Workers", @() generate_parallel_dataset(cfg_bpar, 4, tmp_bpar), 3, 1.0);
  run_bench("Improvement_Parallel_Auto_Workers", @() generate_parallel_dataset(cfg_bpar, "auto", tmp_bpar), 3, 1.0);
  if exist(tmp_bpar, "file"), delete(tmp_bpar); endif

  printf("\n===================================================================\n");
endfunction

function run_bench(name, fn, min_iters, target_seconds)
  if nargin < 3, min_iters = 5; endif
  if nargin < 4, target_seconds = 1.0; endif

  % Warmup
  fn();

  t_start = tic();
  iters = 0;
  while true
    iters = iters + 1;
    fn();
    elapsed = toc(t_start);
    if elapsed >= target_seconds && iters >= min_iters
      break;
    endif
  endwhile

  ns_per_op = (elapsed / iters) * 1e9;
  if ns_per_op < 1e3
    time_str = sprintf("%8.2f ns/op", ns_per_op);
  elseif ns_per_op < 1e6
    time_str = sprintf("%8.2f us/op", ns_per_op / 1e3);
  else
    time_str = sprintf("%8.2f ms/op", ns_per_op / 1e6);
  endif

  printf("%-40s %8d   %12s  (%10.0f ns/op)\n", name, iters, time_str, ns_per_op);
endfunction

function bench_analysis(rg, lambdas)
  [probs, err] = solve_steady_state(rg, lambdas);
  if !err
    compute_average_markings(rg, probs);
  endif
endfunction

function bench_avg_markings_repmat(rg, probs)
  V = rg.num_vertices;
  P = size(rg.vertices, 2);
  avg_markings = (probs' * double(rg.vertices))';
  max_p = max(rg.vertices, [], 1);
  max_tok = max(max_p) + 1;
  D = accumarray([rg.vertices(:) + 1, repmat(1:P, V, 1)(:)], repmat(probs, P, 1), [max_tok, P]);
endfunction

function ok = bench_degree_check(pn)
  arcs = pn.matrix(:, 1:(2 * pn.transitions));
  ok = all(any(arcs, 2)) && all(any(arcs, 1));
endfunction

function bench_pipeline()
  pn = petrinet_generate_random(10, 10);
  pn = petrinet_prune(pn);
  pn = petrinet_add_tokens_randomly(pn);

  rg = generate_reachability_graph(pn, 10, 1000);
  if !rg.is_bounded || rg.num_vertices < 1
    return;
  endif

  lambdas = double(randi([1, 10], pn.transitions, 1));
  [probs, err] = solve_steady_state(rg, lambdas);
  if err
    return;
  endif

  compute_average_markings(rg, probs);
  generate_petrinet_variations(pn, 10, 1, 1000, 3, 1, 10);
endfunction

if !isdeployed() && length(program_name()) > 0
  run_benchmarks();
endif
