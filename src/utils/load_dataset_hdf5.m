## -*- texinfo -*-
## @deftypefn {} {@var{samples} =} load_dataset_hdf5 (@var{filepath})
## @deftypefnx {} {@var{samples} =} load_dataset_hdf5 (@var{filepath}, @var{force_pure_octave})
## Load SPN dataset from HDF5 binary file.
##
## Reads an HDF5 dataset stored in CSR flat pointer layout,
## returning a cell array of sample structs identical to @file{load_jsonl}.
##
## @table @asis
## @item @var{filepath}
## Path to source HDF5 file (.h5).
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, uses Octave's native @code{load -hdf5}.
## @end table
##
## Returns cell array of sample structs.
##
## @seealso{export_dataset_hdf5, load_jsonl}
## @end deftypefn

function samples = load_dataset_hdf5(filepath, force_pure_octave)
  if nargin < 1
    error("load_dataset_hdf5: Requires filepath argument.");
  endif

  if nargin < 2 || isempty(force_pure_octave)
    force_pure_octave = false;
  endif

  if !exist(filepath, "file")
    error("load_dataset_hdf5: File not found: %s", filepath);
  endif

  % Use C++ oct-file acceleration when available
  if !force_pure_octave && exist("import_dataset_hdf5_oct", "file") == 3
    try
      samples = import_dataset_hdf5_oct(filepath);
      return;
    catch err
      % If C++ import fails (e.g. file was written by pure Octave), fall back
    end_try_catch
  endif

  % Pure Octave loading fallback
  loaded = load("-hdf5", filepath);

  if isfield(loaded, "ds")
    % Pure Octave flat layout
    ds = loaded.ds;
    N = length(ds.pointers.num_places);
    samples = cell(N, 1);

    marking_ptr = ds.pointers.marking_ptr;
    edge_ptr = ds.pointers.edge_ptr;
    pn_ptr = ds.pointers.petri_net_ptr;
    num_places = ds.pointers.num_places;
    num_transitions = ds.pointers.num_transitions;
    num_vertices = ds.pointers.num_vertices;
    num_edges = ds.pointers.num_edges;

    uniform_p = (size(ds.data.vertices, 2) > 1);
    curr_v_tok = 0;
    curr_am_idx = 0;
    curr_lv_idx = 0;

    for i = 1:N
      P = num_places(i);
      T = num_transitions(i);
      V = num_vertices(i);
      E = num_edges(i);

      s = struct();

      % Petri net matrix
      pn_len = P * (2 * T + 1);
      raw_pn = ds.data.petri_net(pn_ptr(i) + 1 : pn_ptr(i) + pn_len);
      s.petri_net = reshape(raw_pn, P, 2 * T + 1);

      % Vertices
      if uniform_p
        v_start = marking_ptr(i);
        s.vertices = ds.data.vertices(v_start + 1 : v_start + V, :);
      else
        tok_len = V * P;
        raw_v = ds.data.vertices(curr_v_tok + 1 : curr_v_tok + tok_len);
        s.vertices = reshape(raw_v, V, P);
        curr_v_tok += tok_len;
      endif

      % Edges
      e_start = edge_ptr(i);
      s.edges = ds.data.edges(e_start + 1 : e_start + E, :);
      s.arc_transitions = ds.data.arc_transitions(e_start + 1 : e_start + E);

      % Steady state probs
      v_start = marking_ptr(i);
      s.steady_state_probs = ds.data.steady_state_probs(v_start + 1 : v_start + V);

      % Lambda values
      s.lambda_values = ds.data.lambda_values(curr_lv_idx + 1 : curr_lv_idx + T);
      curr_lv_idx += T;

      % Average markings
      if uniform_p
        s.avg_markings = ds.data.avg_markings(i, :)';
      else
        s.avg_markings = ds.data.avg_markings(curr_am_idx + 1 : curr_am_idx + P);
        curr_am_idx += P;
      endif

      samples{i} = s;
    endfor
  else
    error("load_dataset_hdf5: Unknown HDF5 structure in file: %s", filepath);
  endif
endfunction
