## -*- texinfo -*-
## @deftypefn {} {} generate_html_report (@var{filepath}, @var{stats})
## Write an HTML presentation summary report of the generated SPN dataset.
##
## Produces a styled standalone HTML page presenting dataset metrics, comprehensive
## frequentist statistics, and embedded vector SVG presentation graphs (histograms,
## scatter plots, and distribution box plots) that require zero external dependencies.
##
## @table @asis
## @item @var{filepath}
## Destination file path for the HTML report.
##
## @item @var{stats}
## Struct containing dataset metrics (produced by @code{calculate_stats} or @code{analyze_dataset}).
## @end table
##
## @seealso{calculate_stats, analyze_dataset, format_stats_table}
## @end deftypefn
function generate_html_report(filepath, stats)

  fid = fopen(filepath, "w");
  if fid < 0
    error("Failed to create report file: %s", filepath);
  endif

  N = stats.num_samples;

  % Helper default metric getter
  get_m = @(f) get_metric_or_default(stats, f);

  m_places = get_m("places");
  m_trans = get_m("transitions");
  m_states = get_m("states");
  m_edges = get_m("edges");
  m_density = get_m("density");
  m_tokens = get_m("total_tokens");
  m_tpp = get_m("tokens_per_place");
  m_maxtok = get_m("max_tokens");
  m_maxprob = get_m("max_prob");
  m_probsum = get_m("prob_sum");
  m_ztp = get_m("zero_token_prob");

  % Build SVG presentation graphs
  svg_hist_states = build_svg_histogram("Reachable State Space (Markings S)", m_states, "#2563eb", "states");
  svg_hist_tokens = build_svg_histogram("Total Expected Token Population", m_tokens, "#059669", "tokens");
  svg_hist_maxprob = build_svg_histogram("Max Steady-State Probability (State Concentration)", m_maxprob, "#d97706", "prob");
  svg_hist_places = build_svg_histogram("Number of Places (P)", m_places, "#7c3aed", "places");

  % Scatter plots
  if isfield(stats, "raw") && isfield(stats.raw, "states") && isfield(stats.raw, "total_tokens")
    svg_scatter_st = build_svg_scatter("State Space vs. Token Population", ...
                                        stats.raw.total_tokens, stats.raw.states, ...
                                        "Expected Tokens", "Reachable States (S)", "#2563eb");
  else
    svg_scatter_st = "<div class='no-data'>Insufficient sample data for scatter plot.</div>";
  endif

  if isfield(stats, "raw") && isfield(stats.raw, "states") && isfield(stats.raw, "edges")
    svg_scatter_se = build_svg_scatter("Reachable States vs. State Transitions", ...
                                        stats.raw.states, stats.raw.edges, ...
                                        "States (S)", "State Transitions (E)", "#059669");
  else
    svg_scatter_se = "<div class='no-data'>Insufficient sample data for scatter plot.</div>";
  endif

  % Box-and-whisker summary
  svg_boxplots = build_svg_boxplots(stats);

  % HTML Content
  fprintf(fid, "<!DOCTYPE html>\n");
  fprintf(fid, "<html lang=\"en\">\n");
  fprintf(fid, "<head>\n");
  fprintf(fid, "\t<meta charset=\"UTF-8\">\n");
  fprintf(fid, "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
  fprintf(fid, "\t<title>SPN Dataset Statistics</title>\n");
  fprintf(fid, "\t<style>\n");
  fprintf(fid, "\t\t:root { --primary: #1e40af; --bg: #f8fafc; --card: #ffffff; --border: #e2e8f0; --text: #1e293b; --muted: #64748b; }\n");
  fprintf(fid, "\t\tbody { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 24px; line-height: 1.5; }\n");
  fprintf(fid, "\t\t.container { max-width: 1200px; margin: 0 auto; }\n");
  fprintf(fid, "\t\t.header { background: linear-gradient(135deg, #1e3a8a 0%%, #3b82f6 100%%); color: white; padding: 32px; border-radius: 12px; margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }\n");
  fprintf(fid, "\t\t.header h1 { margin: 0 0 8px 0; font-size: 28px; font-weight: 700; }\n");
  fprintf(fid, "\t\t.header p { margin: 0; opacity: 0.9; font-size: 15px; }\n");
  fprintf(fid, "\t\t.kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }\n");
  fprintf(fid, "\t\t.kpi-card { background: var(--card); padding: 20px; border-radius: 10px; border: 1px solid var(--border); box-shadow: 0 1px 3px rgba(0,0,0,0.05); }\n");
  fprintf(fid, "\t\t.kpi-title { font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--muted); margin-bottom: 6px; }\n");
  fprintf(fid, "\t\t.kpi-value { font-size: 26px; font-weight: 700; color: #0f172a; }\n");
  fprintf(fid, "\t\t.kpi-sub { font-size: 12px; color: var(--muted); margin-top: 4px; }\n");
  fprintf(fid, "\t\t.section-card { background: var(--card); border-radius: 12px; border: 1px solid var(--border); padding: 24px; margin-bottom: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }\n");
  fprintf(fid, "\t\t.section-title { font-size: 18px; font-weight: 700; margin-top: 0; margin-bottom: 16px; color: #0f172a; border-bottom: 2px solid #f1f5f9; padding-bottom: 10px; }\n");
  fprintf(fid, "\t\ttable { width: 100%%; border-collapse: collapse; margin-top: 8px; font-size: 14px; }\n");
  fprintf(fid, "\t\tth, td { border: 1px solid var(--border); padding: 10px 14px; text-align: right; }\n");
  fprintf(fid, "\t\tth:first-child, td:first-child { text-align: left; font-weight: 500; }\n");
  fprintf(fid, "\t\tth { background-color: #f8fafc; font-weight: 600; color: #475569; }\n");
  fprintf(fid, "\t\ttr:hover { background-color: #f1f5f9; }\n");
  fprintf(fid, "\t\t.num { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }\n");
  fprintf(fid, "\t\t.chart-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 20px; }\n");
  fprintf(fid, "\t\t.chart-card { background: #ffffff; border: 1px solid var(--border); border-radius: 10px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.03); overflow: hidden; }\n");
  fprintf(fid, "\t\t.no-data { padding: 40px; text-align: center; color: var(--muted); font-style: italic; }\n");
  fprintf(fid, "\t\t.footer { text-align: center; color: var(--muted); font-size: 13px; margin-top: 32px; padding: 16px; }\n");
  fprintf(fid, "\t</style>\n");
  fprintf(fid, "</head>\n");
  fprintf(fid, "<body>\n");
  fprintf(fid, "<div class=\"container\">\n");

  % Header
  fprintf(fid, "\t<div class=\"header\">\n");
  fprintf(fid, "\t\t<h1>SPN Dataset Statistics</h1>\n");
  fprintf(fid, "\t\t<p>Continuous-Time Markov Chain (CTMC) & Structural Frequentist Analysis Report</p>\n");
  fprintf(fid, "\t</div>\n");

  % KPI Cards
  fprintf(fid, "\t<div class=\"kpi-grid\">\n");
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Sample Count</div><div class=\"kpi-value\">%d</div><div class=\"kpi-sub\">Evaluated SPN Nets</div></div>\n", N);
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Avg Places</div><div class=\"kpi-value\">%.2f</div><div class=\"kpi-sub\">± %.2f std dev</div></div>\n", m_places.mean, m_places.std);
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Avg Transitions</div><div class=\"kpi-value\">%.2f</div><div class=\"kpi-sub\">± %.2f std dev</div></div>\n", m_trans.mean, m_trans.std);
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Avg Reachable States</div><div class=\"kpi-value\">%.1f</div><div class=\"kpi-sub\">Range: [%.0f, %.0f]</div></div>\n", m_states.mean, m_states.min, m_states.max);
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Avg Total Tokens</div><div class=\"kpi-value\">%.2f</div><div class=\"kpi-sub\">Median: %.2f</div></div>\n", m_tokens.mean, m_tokens.median);
  fprintf(fid, "\t\t<div class=\"kpi-card\"><div class=\"kpi-title\">Conservation Sum</div><div class=\"kpi-value\">%.4f</div><div class=\"kpi-sub\">Expected: 1.0000</div></div>\n", m_probsum.mean);
  fprintf(fid, "\t</div>\n");

  % Compatibility Section for automated test validation
  fprintf(fid, "\t<div class=\"section-card\">\n");
  fprintf(fid, "\t\t<h2 class=\"section-title\">Executive Overview</h2>\n");
  fprintf(fid, "\t\t<table>\n");
  fprintf(fid, "\t\t\t<tr><th>Statistic</th><th>Value</th></tr>\n");
  fprintf(fid, "\t\t\t<tr><td>Number of samples</td><td>%d</td></tr>\n", N);
  fprintf(fid, "\t\t\t<tr><td>Average number of places</td><td>%.2f</td></tr>\n", stats.avg_places);
  fprintf(fid, "\t\t\t<tr><td>Average number of transitions</td><td>%.2f</td></tr>\n", stats.avg_transitions);
  fprintf(fid, "\t\t\t<tr><td>Average number of markings</td><td>%.2f</td></tr>\n", stats.avg_markings);
  fprintf(fid, "\t\t\t<tr><td>Average steady-state probabilities</td><td>%.2f</td></tr>\n", stats.avg_steady_state_probs);
  fprintf(fid, "\t\t</table>\n");
  fprintf(fid, "\t</div>\n");

  % Detailed Frequentist Statistics Table
  fprintf(fid, "\t<div class=\"section-card\">\n");
  fprintf(fid, "\t\t<h2 class=\"section-title\">Frequentist Distribution Statistics</h2>\n");
  fprintf(fid, "\t\t<table>\n");
  fprintf(fid, "\t\t\t<tr>\n");
  fprintf(fid, "\t\t\t\t<th>Metric</th>\n");
  fprintf(fid, "\t\t\t\t<th>Count</th>\n");
  fprintf(fid, "\t\t\t\t<th>Mean</th>\n");
  fprintf(fid, "\t\t\t\t<th>StdDev</th>\n");
  fprintf(fid, "\t\t\t\t<th>Min</th>\n");
  fprintf(fid, "\t\t\t\t<th>Q1 (25%%)</th>\n");
  fprintf(fid, "\t\t\t\t<th>Median</th>\n");
  fprintf(fid, "\t\t\t\t<th>Q3 (75%%)</th>\n");
  fprintf(fid, "\t\t\t\t<th>Max</th>\n");
  fprintf(fid, "\t\t\t\t<th>IQR</th>\n");
  fprintf(fid, "\t\t\t</tr>\n");

  metrics_to_show = { ...
    {"Places (P)", m_places}, ...
    {"Transitions (T)", m_trans}, ...
    {"States (Markings S)", m_states}, ...
    {"State Transitions (E)", m_edges}, ...
    {"Branching Density (E/S)", m_density}, ...
    {"Total Expected Tokens", m_tokens}, ...
    {"Tokens Per Place", m_tpp}, ...
    {"Max Observed Tokens", m_maxtok}, ...
    {"Max State Prob (max pi)", m_maxprob}, ...
    {"Prob Sum (sum pi)", m_probsum}, ...
    {"Zero-Token Prob P(M=0)", m_ztp} ...
  };

  for i = 1:length(metrics_to_show)
    entry = metrics_to_show{i};
    m_name = entry{1};
    m_val = entry{2};
    fprintf(fid, "\t\t\t<tr>\n");
    fprintf(fid, "\t\t\t\t<td>%s</td>\n", m_name);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%d</td>\n", m_val.count);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.mean);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.std);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.min);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.p25);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.median);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.p75);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.max);
    fprintf(fid, "\t\t\t\t<td class=\"num\">%.2f</td>\n", m_val.iqr);
    fprintf(fid, "\t\t\t</tr>\n");
  endfor

  fprintf(fid, "\t\t</table>\n");
  fprintf(fid, "\t</div>\n");

  % Presentation Graphs Section
  fprintf(fid, "\t<div class=\"section-card\">\n");
  fprintf(fid, "\t\t<h2 class=\"section-title\">Presentation Graphs & Distributions</h2>\n");
  fprintf(fid, "\t\t<div class=\"chart-grid\">\n");
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_hist_states);
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_hist_tokens);
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_hist_maxprob);
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_hist_places);
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_scatter_st);
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_scatter_se);
  fprintf(fid, "\t\t</div>\n");
  fprintf(fid, "\t\t<div style=\"margin-top: 24px;\">\n");
  fprintf(fid, "\t\t\t<div class=\"chart-card\">%s</div>\n", svg_boxplots);
  fprintf(fid, "\t\t</div>\n");
  fprintf(fid, "\t</div>\n");

  % Footer
  fprintf(fid, "\t<div class=\"footer\">\n");
  fprintf(fid, "\t\tGenerated by SPN Benchmark Dataset Generator • Parity with SPN-Algo-Go\n");
  fprintf(fid, "\t</div>\n");

  fprintf(fid, "</div>\n");
  fprintf(fid, "</body>\n");
  fprintf(fid, "</html>\n");

  fclose(fid);
endfunction

function m = get_metric_or_default(stats, fieldname)
  if isfield(stats, fieldname)
    m = stats.(fieldname);
  else
    m = struct("count", 0, "mean", 0.0, "std", 0.0, "min", 0.0, ...
               "p25", 0.0, "median", 0.0, "p75", 0.0, "max", 0.0, "iqr", 0.0, ...
               "hist_counts", [], "hist_centers", [], "hist_edges", []);
  endif
endfunction

function svg = build_svg_histogram(title_text, m, color, unit_name)
  W = 520;
  H = 260;
  pad_l = 55;
  pad_r = 25;
  pad_t = 45;
  pad_b = 45;
  plot_w = W - pad_l - pad_r;
  plot_h = H - pad_t - pad_b;

  if m.count == 0 || isempty(m.hist_counts)
    svg = sprintf("<svg viewBox=\"0 0 %d %d\" width=\"100%%\" height=\"240\"><text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"#94a3b8\">No data for %s</text></svg>", W, H, W/2, H/2, title_text);
    return;
  endif

  counts = m.hist_counts;
  nbins = length(counts);
  max_c = max(counts);
  if max_c == 0
    max_c = 1;
  endif

  s_buf = {};
  s_buf{end + 1} = sprintf("<svg viewBox=\"0 0 %d %d\" width=\"100%%\" height=\"250\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background:#ffffff; font-family:sans-serif;\">", W, H);

  % Title & subtitle
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"22\" font-size=\"14\" font-weight=\"bold\" fill=\"#0f172a\">%s</text>", pad_l, title_text);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"37\" font-size=\"11\" fill=\"#64748b\">Mean: %.2f | Std: %.2f | Min: %.2f | Max: %.2f</text>", pad_l, m.mean, m.std, m.min, m.max);

  % Y grid lines & labels (3 ticks: 0, max_c/2, max_c)
  y_ticks = [0, ceil(max_c / 2), max_c];
  for y_val = y_ticks
    y_pos = pad_t + plot_h - (double(y_val) / double(max_c)) * plot_h;
    s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#f1f5f9\" stroke-width=\"1\"/>", pad_l, y_pos, pad_l + plot_w, y_pos);
    s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%.1f\" font-size=\"10\" fill=\"#94a3b8\" text-anchor=\"end\" dominant-baseline=\"middle\">%d</text>", pad_l - 8, y_pos, y_val);
  endfor

  % Axes lines
  s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#cbd5e1\" stroke-width=\"1\"/>", pad_l, pad_t, pad_l, pad_t + plot_h);
  s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#cbd5e1\" stroke-width=\"1\"/>", pad_l, pad_t + plot_h, pad_l + plot_w, pad_t + plot_h);

  % Bars
  bar_gap = 4;
  total_bar_w = plot_w / nbins;
  bar_w = max(2, total_bar_w - bar_gap);

  for i = 1:nbins
    c = counts(i);
    bh = (double(c) / double(max_c)) * plot_h;
    bx = pad_l + (i - 1) * total_bar_w + bar_gap / 2;
    by = pad_t + plot_h - bh;

    % Tooltip on hover
    val_label = sprintf("%.2f", m.hist_centers(i));
    s_buf{end + 1} = sprintf("<rect x=\"%.1f\" y=\"%.1f\" width=\"%.1f\" height=\"%.1f\" fill=\"%s\" rx=\"2\"><title>Bin ~%s %s: %d sample(s)</title></rect>", ...
                             bx, by, bar_w, bh, color, val_label, unit_name, c);

    % Optional count text on top of bar if space permits
    if bh > 14
      s_buf{end + 1} = sprintf("<text x=\"%.1f\" y=\"%.1f\" font-size=\"9\" font-weight=\"600\" fill=\"#ffffff\" text-anchor=\"middle\">%d</text>", ...
                               bx + bar_w / 2, by + 11, c);
    endif

    % X labels (first, middle, last)
    if i == 1 || i == round(nbins / 2) || i == nbins
      s_buf{end + 1} = sprintf("<text x=\"%.1f\" y=\"%d\" font-size=\"10\" fill=\"#64748b\" text-anchor=\"middle\">%s</text>", ...
                               bx + bar_w / 2, pad_t + plot_h + 16, val_label);
    endif
  endfor

  s_buf{end + 1} = "</svg>";
  svg = strjoin(s_buf, "\n");
endfunction

function svg = build_svg_scatter(title_text, x_raw, y_raw, x_label, y_label, point_color)
  W = 520;
  H = 260;
  pad_l = 60;
  pad_r = 25;
  pad_t = 45;
  pad_b = 45;
  plot_w = W - pad_l - pad_r;
  plot_h = H - pad_t - pad_b;

  x_raw = double(x_raw(:));
  y_raw = double(y_raw(:));
  valid_idx = find(!isnan(x_raw) & !isnan(y_raw) & !isinf(x_raw) & !isinf(y_raw));
  x = x_raw(valid_idx);
  y = y_raw(valid_idx);

  if isempty(x) || length(x) < 2
    svg = sprintf("<svg viewBox=\"0 0 %d %d\" width=\"100%%\" height=\"240\"><text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"#94a3b8\">Insufficient points for %s</text></svg>", W, H, W/2, H/2, title_text);
    return;
  endif

  min_x = min(x); max_x = max(x);
  min_y = min(y); max_y = max(y);
  if min_x == max_x, min_x = min_x - 1; max_x = max_x + 1; endif
  if min_y == max_y, min_y = min_y - 1; max_y = max_y + 1; endif

  % 5% margins
  dx = max_x - min_x;
  dy = max_y - min_y;
  x0 = min_x - 0.05 * dx; x1 = max_x + 0.05 * dx;
  y0 = min_y - 0.05 * dy; y1 = max_y + 0.05 * dy;

  s_buf = {};
  s_buf{end + 1} = sprintf("<svg viewBox=\"0 0 %d %d\" width=\"100%%\" height=\"250\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background:#ffffff; font-family:sans-serif;\">", W, H);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"22\" font-size=\"14\" font-weight=\"bold\" fill=\"#0f172a\">%s</text>", pad_l, title_text);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"37\" font-size=\"11\" fill=\"#64748b\">Correlation scatter plot (N = %d)</text>", pad_l, length(x));

  % Axes
  s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#cbd5e1\" stroke-width=\"1\"/>", pad_l, pad_t, pad_l, pad_t + plot_h);
  s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#cbd5e1\" stroke-width=\"1\"/>", pad_l, pad_t + plot_h, pad_l + plot_w, pad_t + plot_h);

  % Y axis label
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%.1f\" font-size=\"10\" fill=\"#94a3b8\" text-anchor=\"end\">%.0f</text>", pad_l - 6, pad_t + 10, y1);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%.1f\" font-size=\"10\" fill=\"#94a3b8\" text-anchor=\"end\">%.0f</text>", pad_l - 6, pad_t + plot_h, y0);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\" fill=\"#64748b\" text-anchor=\"middle\">%s</text>", pad_l + plot_w / 2, pad_t + plot_h + 32, x_label);

  % X axis labels
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\" fill=\"#94a3b8\" text-anchor=\"start\">%.1f</text>", pad_l, pad_t + plot_h + 16, x0);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\" fill=\"#94a3b8\" text-anchor=\"end\">%.1f</text>", pad_l + plot_w, pad_t + plot_h + 16, x1);

  % Plot points
  for i = 1:length(x)
    px = pad_l + ((x(i) - x0) / (x1 - x0)) * plot_w;
    py = pad_t + plot_h - ((y(i) - y0) / (y1 - y0)) * plot_h;
    s_buf{end + 1} = sprintf("<circle cx=\"%.1f\" cy=\"%.1f\" r=\"4\" fill=\"%s\" fill-opacity=\"0.6\" stroke=\"%s\" stroke-width=\"1\"><title>%s: %.2f, %s: %.2f</title></circle>", ...
                             px, py, point_color, point_color, x_label, x(i), y_label, y(i));
  endfor

  s_buf{end + 1} = "</svg>";
  svg = strjoin(s_buf, "\n");
endfunction

function svg = build_svg_boxplots(stats)
  W = 1100;
  H = 260;
  pad_l = 220;
  pad_r = 40;
  pad_t = 45;
  pad_b = 30;
  plot_w = W - pad_l - pad_r;

  items = { ...
    {"Places (P)", stats.places, "#7c3aed"}, ...
    {"Transitions (T)", stats.transitions, "#6366f1"}, ...
    {"States (S)", stats.states, "#2563eb"}, ...
    {"Total Expected Tokens", stats.total_tokens, "#059669"}, ...
    {"Tokens Per Place", stats.tokens_per_place, "#10b981"}, ...
    {"Max State Prob", stats.max_prob, "#d97706"} ...
  };

  s_buf = {};
  s_buf{end + 1} = sprintf("<svg viewBox=\"0 0 %d %d\" width=\"100%%\" height=\"280\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background:#ffffff; font-family:sans-serif;\">", W, H);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"22\" font-size=\"15\" font-weight=\"bold\" fill=\"#0f172a\">Distribution Box-and-Whisker Summary</text>", pad_l);
  s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"37\" font-size=\"11\" fill=\"#64748b\">Showing Min (left whisker), Q1, Median (bold bar), Q3, Max (right whisker) for key metrics</text>", pad_l);

  n_items = length(items);
  row_h = (H - pad_t - pad_b) / n_items;

  for i = 1:n_items
    name = items{i}{1};
    m = items{i}{2};
    c = items{i}{3};
    cy = pad_t + (i - 0.5) * row_h;

    % Row label
    s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%.1f\" font-size=\"12\" font-weight=\"600\" fill=\"#334155\" text-anchor=\"end\" dominant-baseline=\"middle\">%s</text>", ...
                             pad_l - 16, cy, name);

    if m.count == 0 || m.max == m.min
      % Single value or empty
      val = m.mean;
      s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#e2e8f0\" stroke-width=\"1\"/>", pad_l, cy, pad_l + plot_w, cy);
      s_buf{end + 1} = sprintf("<circle cx=\"%d\" cy=\"%.1f\" r=\"5\" fill=\"%s\"/>", pad_l + plot_w/2, cy, c);
      s_buf{end + 1} = sprintf("<text x=\"%d\" y=\"%.1f\" font-size=\"10\" fill=\"#64748b\" text-anchor=\"start\"> (fixed: %.2f)</text>", pad_l + plot_w/2 + 10, cy, val);
      continue;
    endif

    % Normalization across metric range [min, max] with small margin
    scale = @(val) pad_l + ((val - m.min) / (m.max - m.min)) * plot_w;
    x_min = scale(m.min);
    x_p25 = scale(m.p25);
    x_med = scale(m.median);
    x_p75 = scale(m.p75);
    x_max = scale(m.max);

    % Background track
    s_buf{end + 1} = sprintf("<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#f1f5f9\" stroke-width=\"6\" rx=\"3\"/>", pad_l, cy, pad_l + plot_w, cy);

    % Whisker line from Min to Max
    s_buf{end + 1} = sprintf("<line x1=\"%.1f\" y1=\"%.1f\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"#94a3b8\" stroke-width=\"2\"/>", x_min, cy, x_max, cy);
    % Whisker caps
    s_buf{end + 1} = sprintf("<line x1=\"%.1f\" y1=\"%.1f\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"#94a3b8\" stroke-width=\"2\"/>", x_min, cy - 6, x_min, cy + 6);
    s_buf{end + 1} = sprintf("<line x1=\"%.1f\" y1=\"%.1f\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"#94a3b8\" stroke-width=\"2\"/>", x_max, cy - 6, x_max, cy + 6);

    % Box from Q1 to Q3
    box_w = max(4, x_p75 - x_p25);
    s_buf{end + 1} = sprintf("<rect x=\"%.1f\" y=\"%.1f\" width=\"%.1f\" height=\"16\" fill=\"%s\" fill-opacity=\"0.35\" stroke=\"%s\" stroke-width=\"1.5\" rx=\"3\"/>", ...
                             x_p25, cy - 8, box_w, c, c);

    % Median line
    s_buf{end + 1} = sprintf("<line x1=\"%.1f\" y1=\"%.1f\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"%s\" stroke-width=\"3.5\"/>", x_med, cy - 8, x_med, cy + 8, c);

    % Text values (Min, Median, Max)
    s_buf{end + 1} = sprintf("<text x=\"%.1f\" y=\"%.1f\" font-size=\"9\" fill=\"#64748b\" text-anchor=\"middle\">%.1f</text>", x_min, cy + 16, m.min);
    s_buf{end + 1} = sprintf("<text x=\"%.1f\" y=\"%.1f\" font-size=\"10\" font-weight=\"bold\" fill=\"#0f172a\" text-anchor=\"middle\">%.2f</text>", x_med, cy - 11, m.median);
    s_buf{end + 1} = sprintf("<text x=\"%.1f\" y=\"%.1f\" font-size=\"9\" fill=\"#64748b\" text-anchor=\"middle\">%.1f</text>", x_max, cy + 16, m.max);
  endfor

  s_buf{end + 1} = "</svg>";
  svg = strjoin(s_buf, "\n");
endfunction
