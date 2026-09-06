## -*- texinfo -*-
## @deftypefn {} {} export_dataset_hdf5 (@var{source}, @var{filepath})
## @deftypefnx {} {} export_dataset_hdf5 (@var{source}, @var{filepath}, @var{compression_level})
## @deftypefnx {} {} export_dataset_hdf5 (@var{source}, @var{filepath}, @var{compression_level}, @var{force_pure_octave})
## Export SPN dataset to HDF5 binary format using CSR flat layout.
##
## Exports generated SPN samples to HDF5 binary storage using either high-performance
## C++ acceleration (@file{export_dataset_hdf5_oct}) with chunked byte-shuffle and deflate
## filters, or pure Octave fallback. Uses CSR flat contiguous arrays with index pointers.
##
## @table @asis
## @item @var{source}
## Cell array of sample structs, or string file path to an existing JSONL dataset.
##
## @item @var{filepath}
## Destination file path for the HDF5 output (.h5).
##
## @item @var{compression_level}
## Deflate compression level from 0 (uncompressed) to 9 (maximum gzip). Default is 4.
##
## @item @var{force_pure_octave}
## Optional boolean flag (default: false). When true, bypasses the compiled C++ oct-file
## and utilizes pure Octave HDF5 serialization.
## @end table
##
## @seealso{load_dataset_hdf5, load_jsonl, generate_parallel_dataset}
## @end deftypefn

function export_dataset_hdf5(source, filepath, compression_level, force_pure_octave)
  if nargin < 2
    error("export_dataset_hdf5: Requires at least source and filepath arguments.");
  endif

  if nargin < 3 || isempty(compression_level)
    compression_level = 4;
  endif

  if nargin < 4 || isempty(force_pure_octave)
    force_pure_octave = false;
  endif

  % If source is a JSONL file path, load records
  if ischar(source)
    if !exist(source, "file")
      error("export_dataset_hdf5: Source file not found: %s", source);
    endif
    samples = load_jsonl(source);
  elseif iscell(source)
    samples = source;
  else
    error("export_dataset_hdf5: Source must be a cell array of structs or a JSONL filepath.");
  endif

  % Ensure output directory exists
  out_dir = fileparts(filepath);
  if !isempty(out_dir) && !exist(out_dir, "dir")
    mkdir(out_dir);
  endif

  % Use C++ oct-file acceleration when available
  if !force_pure_octave && exist("export_dataset_hdf5_oct", "file") == 3
    export_dataset_hdf5_oct(samples, filepath, compression_level);
    return;
  endif

  % Pure Octave fallback implementation
  export_dataset_hdf5_pure(samples, filepath);
endfunction

function export_dataset_hdf5_pure(samples, filepath)
  N = length(samples);

  % Flat layout
  ds = struct();
  ds.pointers = struct();
  ds.data = struct();

    num_places = zeros(N, 1, "int32");
    num_transitions = zeros(N, 1, "int32");
    num_vertices = zeros(N, 1, "int32");
    num_edges = zeros(N, 1, "int32");

    marking_ptr = zeros(N + 1, 1, "int32");
    edge_ptr = zeros(N + 1, 1, "int32");
    petri_net_ptr = zeros(N + 1, 1, "int32");

    total_v = 0;
    total_e = 0;
    total_pn = 0;
    uniform_p = true;
    p0 = 0;
    if N > 0
      p0 = size(samples{1}.petri_net, 1);
    endif

    for i = 1:N
      s = samples{i};
      P = size(s.petri_net, 1);
      T = (size(s.petri_net, 2) - 1) / 2;
      V = size(s.vertices, 1);
      E = size(s.edges, 1);

      if P != p0
        uniform_p = false;
      endif

      num_places(i) = int32(P);
      num_transitions(i) = int32(T);
      num_vertices(i) = int32(V);
      num_edges(i) = int32(E);

      marking_ptr(i) = int32(total_v);
      edge_ptr(i) = int32(total_e);
      petri_net_ptr(i) = int32(total_pn);

      total_v += V;
      total_e += E;
      total_pn += numel(s.petri_net);
    endfor
    marking_ptr(N + 1) = int32(total_v);
    edge_ptr(N + 1) = int32(total_e);
    petri_net_ptr(N + 1) = int32(total_pn);

    ds.pointers.num_places = num_places;
    ds.pointers.num_transitions = num_transitions;
    ds.pointers.num_vertices = num_vertices;
    ds.pointers.num_edges = num_edges;
    ds.pointers.marking_ptr = marking_ptr;
    ds.pointers.edge_ptr = edge_ptr;
    ds.pointers.petri_net_ptr = petri_net_ptr;

    all_edges = zeros(total_e, 2, "int32");
    all_arc_trans = zeros(total_e, 1, "int32");
    all_ssp = zeros(total_v, 1);
    all_lambda = cell(N, 1);
    all_pn = zeros(total_pn, 1, "int32");

    curr_e = 0;
    curr_v = 0;
    curr_pn = 0;

    for i = 1:N
      s = samples{i};
      E = size(s.edges, 1);
      V = size(s.vertices, 1);
      PN_len = numel(s.petri_net);

      if E > 0
        all_edges(curr_e + 1 : curr_e + E, :) = int32(s.edges);
        all_arc_trans(curr_e + 1 : curr_e + E) = int32(get_arc_transitions(s, E));
        curr_e += E;
      endif

      if V > 0
        all_ssp(curr_v + 1 : curr_v + V) = double(s.steady_state_probs(:));
        curr_v += V;
      endif

      all_pn(curr_pn + 1 : curr_pn + PN_len) = int32(s.petri_net(:));
      curr_pn += PN_len;
      all_lambda{i} = double(s.lambda_values(:));
    endfor

    ds.data.edges = all_edges;
    ds.data.arc_transitions = all_arc_trans;
    ds.data.steady_state_probs = all_ssp;
    ds.data.lambda_values = vertcat(all_lambda{:});
    ds.data.petri_net = all_pn;

    if uniform_p && N > 0
      all_vert = zeros(total_v, p0, "int32");
      all_am = zeros(N, p0);
      curr_v = 0;
      for i = 1:N
        s = samples{i};
        V = size(s.vertices, 1);
        if V > 0
          all_vert(curr_v + 1 : curr_v + V, :) = int32(s.vertices);
          curr_v += V;
        endif
        am_val = get_avg_markings(s);
        all_am(i, :) = double(am_val(:))';
      endfor
      ds.data.vertices = all_vert;
      ds.data.avg_markings = all_am;
    else
      vert_cells = cell(N, 1);
      am_cells = cell(N, 1);
      for i = 1:N
        vert_cells{i} = int32(samples{i}.vertices(:));
        am_val = get_avg_markings(samples{i});
        am_cells{i} = double(am_val(:));
      endfor
      ds.data.vertices = vertcat(vert_cells{:});
      ds.data.avg_markings = vertcat(am_cells{:});
    endif

    save("-hdf5", filepath, "ds");
endfunction

function am = get_avg_markings(s)
  if isfield(s, "average_markings") && !isempty(s.average_markings)
    am = s.average_markings(:);
  elseif isfield(s, "avg_markings") && !isempty(s.avg_markings)
    am = s.avg_markings(:);
  else
    am = [];
  endif
endfunction

function at = get_arc_transitions(s, num_edges)
  if isfield(s, "arc_transitions") && !isempty(s.arc_transitions)
    at = s.arc_transitions(:);
  else
    at = zeros(num_edges, 1, "int32");
  endif
endfunction
