## -*- texinfo -*-
## @deftypefn {} {@var{items} =} load_jsonl (@var{filepath})
## Read a JSON Lines (JSONL) file into a cell array of structs.
##
## Parses each non-empty newline-delimited line via @code{jsondecode}. Uses geometric
## chunk preallocation for efficiency on large dataset files.
##
## @table @asis
## @item @var{filepath}
## Path to the target JSONL dataset file.
## @end table
##
## Returns cell array of decoded item structs.
##
## @seealso{load_json, write_sample_jsonl}
## @end deftypefn
function items = load_jsonl(filepath)

  fid = fopen(filepath, "r");
  if fid < 0
    error("Failed to open JSONL file: %s", filepath);
  endif

  capacity = 64;
  items = cell(capacity, 1);
  count = 0;

  while !feof(fid)
    line = fgetl(fid);
    if ischar(line) && !isempty(strtrim(line))
      count = count + 1;
      if count > capacity
        capacity = capacity * 2;
        items{capacity} = [];
      endif
      items{count} = jsondecode(line);
    endif
  endwhile

  fclose(fid);
  items = items(1:count);
endfunction
