## -*- texinfo -*-
## @deftypefn {} {} write_sample_jsonl (@var{fid_or_path}, @var{pn}, @var{rg}, @var{lambda_values}, @var{steady_state_probs}, @var{avg_markings}, @var{marking_densities})
## Format and write a single SPN sample to a JSONL dataset stream or file.
##
## Produces a JSON record maintaining strict schema parity with @file{SPN-Algo-Go}.
##
## @table @asis
## @item @var{fid_or_path}
## Open file descriptor integer or target string file path.
##
## @item @var{pn}
## Petri net struct.
##
## @item @var{rg}
## Reachability graph struct.
##
## @item @var{lambda_values}
## Vector of transition firing rates.
##
## @item @var{steady_state_probs}
## Vector of steady-state marking probabilities.
##
## @item @var{avg_markings}
## Vector of average place token counts.
##
## @item @var{marking_densities}
## Cell array of discrete token probability densities per place.
## @end table
##
## @seealso{load_jsonl, generate_samples_chunk}
## @end deftypefn
function write_sample_jsonl(fid_or_path, pn, rg, lambda_values, steady_state_probs, avg_markings, marking_densities)

  close_on_exit = false;
  if ischar(fid_or_path)
    fid = fopen(fid_or_path, "a");
    if fid < 0
      error("Failed to open output file: %s", fid_or_path);
    endif
    close_on_exit = true;
  else
    fid = fid_or_path;
  endif

  sample = struct();

  % 1. petri_net matrix
  sample.petri_net = pn.matrix;

  % 2. vertices matrix
  sample.vertices = rg.vertices;

  % 3. edges (0-based)
  if rg.num_edges == 0
    sample.edges = {};
  else
    e = double(rg.edges) - 1;
    if size(e, 1) == 1
      sample.edges = {e};
    else
      sample.edges = e;
    endif
  endif

  % 4. arc_transitions (0-based)
  if isempty(rg.arc_transitions)
    sample.arc_transitions = {};
  else
    at = double(rg.arc_transitions(:)') - 1;
    if length(at) == 1
      sample.arc_transitions = {at(1)};
    else
      sample.arc_transitions = at;
    endif
  endif

  % 5. lambda_values
  if isempty(lambda_values)
    sample.lambda_values = [];
  else
    lv = double(lambda_values(:)');
    if length(lv) == 1
      sample.lambda_values = {lv(1)};
    else
      sample.lambda_values = lv;
    endif
  endif

  % 6. steady_state_probs
  if isempty(steady_state_probs)
    sample.steady_state_probs = [];
  else
    sp = double(steady_state_probs(:)');
    if length(sp) == 1
      sample.steady_state_probs = {sp(1)};
    else
      sample.steady_state_probs = sp;
    endif
  endif

  % 7. average_markings
  if isempty(avg_markings)
    sample.average_markings = [];
  else
    am = double(avg_markings(:)');
    if length(am) == 1
      sample.average_markings = {am(1)};
    else
      sample.average_markings = am;
    endif
  endif

  % 8. marking_densities
  if isempty(marking_densities)
    sample.marking_densities = {};
  else
    num_dens = length(marking_densities);
    dens = cell(1, num_dens);
    for p = 1:num_dens
      dp = double(marking_densities{p}(:)');
      if length(dp) == 1
        dens{p} = {dp(1)};
      else
        dens{p} = dp;
      endif
    endfor
    sample.marking_densities = dens;
  endif


  fprintf(fid, "%s\n", jsonencode(sample));

  if close_on_exit
    fclose(fid);
  endif
endfunction
