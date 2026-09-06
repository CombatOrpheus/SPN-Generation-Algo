## -*- texinfo -*-
## @deftypefn {} {@var{data} =} load_json (@var{filepath})
## Load and decode data from a JSON file.
##
## Reads the raw text content of @var{filepath} and parses it into Octave data structures
## using @code{jsondecode}.
##
## @table @asis
## @item @var{filepath}
## Path to the target JSON file.
## @end table
##
## Returns decoded data struct or cell array.
##
## @seealso{save_json, load_jsonl}
## @end deftypefn
function data = load_json(filepath)
  fid = fopen(filepath, "r");
  if fid < 0
    error("Failed to open JSON file: %s", filepath);
  endif
  raw = fread(fid, "*char")';
  fclose(fid);
  data = jsondecode(raw);
endfunction
