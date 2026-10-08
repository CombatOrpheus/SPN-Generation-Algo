## -*- texinfo -*-
## @deftypefn {} {@var{table_str} =} format_stats_table (@var{stats})
## Format computed frequentist dataset statistics into a clean ASCII table.
##
## Outputs a multi-line formatted string summarizing sample count, mean,
## standard deviation, min, Q1 (25%), median (50%), Q3 (75%), max, and IQR
## across structural dimensions and steady-state performance measures.
##
## @table @asis
## @item @var{stats}
## Struct returned by @code{calculate_stats} or @code{analyze_dataset}.
## @end table
##
## Returns string @var{table_str}.
##
## @seealso{calculate_stats, analyze_dataset, generate_html_report}
## @end deftypefn
function table_str = format_stats_table(stats)
  if isempty(stats) || !isfield(stats, "num_samples") || stats.num_samples == 0
    table_str = "No samples evaluated in dataset.\n";
    return;
  endif

  N = stats.num_samples;

  header = sprintf([ ...
    "====================================================================================================\n" ...
    "                        SPN Dataset Frequentist Statistics (N = %d)\n" ...
    "====================================================================================================\n" ...
    "%-24s %9s %9s %8s %8s %8s %8s %8s %8s\n" ...
    "----------------------------------------------------------------------------------------------------\n" ...
  ], N, "Metric", "Mean", "StdDev", "Min", "Q1", "Median", "Q3", "Max", "IQR");

  rows = {};

  if isfield(stats, "places")
    rows{end + 1} = format_row("Places (P)", stats.places);
  endif
  if isfield(stats, "transitions")
    rows{end + 1} = format_row("Transitions (T)", stats.transitions);
  endif
  if isfield(stats, "states")
    rows{end + 1} = format_row("States (Markings S)", stats.states);
  endif
  if isfield(stats, "edges")
    rows{end + 1} = format_row("State Transitions (E)", stats.edges);
  endif
  if isfield(stats, "density")
    rows{end + 1} = format_row("State Density (E/S)", stats.density);
  endif
  if isfield(stats, "total_tokens")
    rows{end + 1} = format_row("Total Expected Tokens", stats.total_tokens);
  endif
  if isfield(stats, "tokens_per_place")
    rows{end + 1} = format_row("Tokens Per Place", stats.tokens_per_place);
  endif
  if isfield(stats, "max_tokens")
    rows{end + 1} = format_row("Max Observed Tokens", stats.max_tokens);
  endif
  if isfield(stats, "max_prob")
    rows{end + 1} = format_row("Max State Prob (max pi)", stats.max_prob);
  endif
  if isfield(stats, "prob_sum")
    rows{end + 1} = format_row("Prob Sum (sum pi)", stats.prob_sum);
  endif
  if isfield(stats, "zero_token_prob")
    rows{end + 1} = format_row("Zero-Token Prob P(M=0)", stats.zero_token_prob);
  endif

  footer = sprintf("====================================================================================================\n");

  table_str = [header, strjoin(rows, "\n"), "\n", footer];
endfunction

function line = format_row(name, m)
  if m.count == 0
    line = sprintf("%-24s       N/A       N/A      N/A      N/A      N/A      N/A      N/A      N/A", name);
  else
    line = sprintf("%-24s %9.2f %9.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f", ...
                   name, m.mean, m.std, m.min, m.p25, m.median, m.p75, m.max, m.iqr);
  endif
endfunction
