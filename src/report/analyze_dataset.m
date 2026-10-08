## -*- texinfo -*-
## @deftypefn {} {@var{stats} =} analyze_dataset (@var{filepath})
## @deftypefnx {} {@var{stats} =} analyze_dataset (@var{filepath}, @var{quiet})
## Run comprehensive frequentist statistical analysis on an existing SPN dataset.
##
## Analyzes dataset files in either JSON Lines (@file{.jsonl}) or HDF5 (@file{.h5})
## format. Evaluates distributions of places, transitions, reachability states,
## state transitions, and steady-state performance metrics (expected token population,
## place occupancy, max observed tokens, steady-state probabilities, and starvation).
##
## Outputs a formatted frequentist statistics table to the console and generates
## a self-contained HTML presentation report with vector SVG presentation graphs.
##
## @table @asis
## @item @var{filepath}
## Filepath to existing dataset file (.jsonl or .h5).
##
## @item @var{quiet}
## Optional boolean flag (default: false). When true, suppresses console table output.
## @end table
##
## Returns struct @var{stats} containing all computed frequentist statistics.
##
## @seealso{calculate_stats, format_stats_table, generate_html_report, load_jsonl, load_dataset_hdf5}
## @end deftypefn
function stats = analyze_dataset(filepath, quiet)
  if nargin < 1 || isempty(filepath)
    error("analyze_dataset: Requires filepath argument.");
  endif

  if nargin < 2 || isempty(quiet)
    quiet = false;
  endif

  if !exist(filepath, "file")
    error("analyze_dataset: File not found: %s", filepath);
  endif

  [~, ~, ext] = fileparts(filepath);

  if strcmpi(ext, ".h5") || strcmpi(ext, ".hdf5")
    if !quiet
      printf("Loading HDF5 dataset from: %s\n", filepath);
    endif
    samples = load_dataset_hdf5(filepath);
  else
    if !quiet
      printf("Streaming JSONL dataset from: %s\n", filepath);
    endif
    samples = load_jsonl(filepath);
  endif

  % Calculate frequentist statistics
  stats = calculate_stats(samples);

  if !quiet
    table_str = format_stats_table(stats);
    printf("\n%s\n", table_str);
  endif

  % Generate HTML presentation report with embedded vector SVG graphs
  report_path = [filepath, ".html"];
  generate_html_report(report_path, stats);

  if !quiet
    printf("Generated HTML presentation report with graphs: %s\n\n", report_path);
  endif
endfunction
