function test_hdf5()
  % TEST_HDF5 Test suite for HDF5 dataset export and import.
  printf("Running test_hdf5...\n");

  test_dir = fullfile(tempdir(), "test_spn_hdf5");
  if exist(test_dir, "dir")
    confirm_recursive_rmdir(false, "local");
    rmdir(test_dir, "s");
  endif
  mkdir(test_dir);

  % Create deterministic synthetic test samples
  s1 = struct();
  s1.petri_net = int32([1, 0, 1; 0, 1, 0]); % P=2, T=1
  s1.vertices = int32([1, 0; 0, 1]);        % V=2, P=2
  s1.edges = int32([0, 1]);                 % E=1, 2 (0-based)
  s1.arc_transitions = int32([1]);
  s1.lambda_values = [2.0];
  s1.steady_state_probs = [0.4; 0.6];
  s1.avg_markings = [0.4; 0.6];

  s2 = struct();
  s2.petri_net = int32([1, 0, 2; 0, 1, 0]); % P=2, T=1
  s2.vertices = int32([2, 0; 1, 1; 0, 2]);  % V=3, P=2
  s2.edges = int32([0, 1; 1, 2]);           % E=2
  s2.arc_transitions = int32([1; 1]);
  s2.lambda_values = [3.0];
  s2.steady_state_probs = [0.2; 0.3; 0.5];
  s2.avg_markings = [0.7; 1.3];

  samples = {s1; s2};

  % 1. C++ Flat layout round-trip
  c_flat_path = fullfile(test_dir, "c_flat.h5");
  export_dataset_hdf5(samples, c_flat_path, 4, false);
  s_c_flat = load_dataset_hdf5(c_flat_path, false);
  assert(length(s_c_flat) == 2, "C++ Flat: count mismatch");
  assert(isequal(s_c_flat{1}.petri_net, s1.petri_net));
  assert(isequal(s_c_flat{1}.vertices, s1.vertices));
  assert(isequal(s_c_flat{1}.edges, s1.edges));
  assert(isequal(s_c_flat{2}.petri_net, s2.petri_net));
  assert(isequal(s_c_flat{2}.vertices, s2.vertices));
  assert(isequal(s_c_flat{2}.edges, s2.edges));

  % 2. Pure Octave Flat layout round-trip
  p_flat_path = fullfile(test_dir, "p_flat.h5");
  export_dataset_hdf5(samples, p_flat_path, 0, true);
  s_p_flat = load_dataset_hdf5(p_flat_path, true);
  assert(length(s_p_flat) == 2, "Pure Flat: count mismatch");
  assert(isequal(s_p_flat{1}.petri_net, s1.petri_net));
  assert(isequal(s_p_flat{1}.vertices, s1.vertices));
  assert(isequal(s_p_flat{1}.edges, s1.edges));
  assert(isequal(s_p_flat{2}.petri_net, s2.petri_net));

  % 3. Mixed SPN test (P=2 and P=3)
  s3 = struct();
  s3.petri_net = int32([1, 0, 0, 1, 1; 0, 1, 1, 0, 0; 0, 0, 1, 0, 1]); % P=3, T=2
  s3.vertices = int32([1, 0, 1; 0, 1, 1; 1, 1, 0; 0, 0, 2]);          % V=4, P=3
  s3.edges = int32([0, 1; 1, 2; 2, 3]);                                % E=3
  s3.arc_transitions = int32([1; 2; 1]);
  s3.lambda_values = [1.5; 2.5];
  s3.steady_state_probs = [0.25; 0.25; 0.25; 0.25];
  s3.avg_markings = [0.5; 0.5; 1.0];

  mixed_samples = {s1; s3};

  % Mixed C++ Flat
  mixed_c_flat = fullfile(test_dir, "mixed_c_flat.h5");
  export_dataset_hdf5(mixed_samples, mixed_c_flat, 4, false);
  m_cf = load_dataset_hdf5(mixed_c_flat, false);
  assert(length(m_cf) == 2);
  assert(isequal(m_cf{1}.petri_net, s1.petri_net));
  assert(isequal(m_cf{2}.petri_net, s3.petri_net));
  assert(isequal(m_cf{1}.vertices, s1.vertices));
  assert(isequal(m_cf{2}.vertices, s3.vertices));

  % Mixed Pure Flat
  mixed_p_flat = fullfile(test_dir, "mixed_p_flat.h5");
  export_dataset_hdf5(mixed_samples, mixed_p_flat, 0, true);
  m_pf = load_dataset_hdf5(mixed_p_flat, true);
  assert(length(m_pf) == 2);
  assert(isequal(m_pf{1}.petri_net, s1.petri_net));
  assert(isequal(m_pf{2}.petri_net, s3.petri_net));

  % 4. Compression level comparison on a realistic synthetic sample set
  big_s = struct();
  big_s.petri_net = int32(zeros(10, 21));
  big_s.vertices = int32(zeros(500, 10));
  big_s.edges = int32(zeros(1000, 2));
  big_s.arc_transitions = int32(ones(1000, 1));
  big_s.lambda_values = ones(10, 1);
  big_s.steady_state_probs = ones(500, 1) / 500;
  big_s.avg_markings = ones(10, 1);
  big_samples = repmat({big_s}, 5, 1);

  uncomp_path = fullfile(test_dir, "uncompressed.h5");
  comp_path = fullfile(test_dir, "compressed.h5");
  export_dataset_hdf5(big_samples, uncomp_path, 0, false);
  export_dataset_hdf5(big_samples, comp_path, 6, false);

  uncomp_stat = stat(uncomp_path);
  comp_stat = stat(comp_path);
  assert(comp_stat.size < uncomp_stat.size, "Compression failed to reduce file size.");

  % Clean up
  confirm_recursive_rmdir(false, "local");
  rmdir(test_dir, "s");
  printf("test_hdf5 PASSED\n");
endfunction
