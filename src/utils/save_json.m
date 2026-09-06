## -*- texinfo -*-
## @deftypefn {} {} save_json (@var{filepath}, @var{data})
## Encode and save data structure to a JSON file.
##
## Encodes @var{data} via @code{jsonencode}, creates parent directories if needed,
## and writes formatted JSON to @var{filepath}.
##
## @table @asis
## @item @var{filepath}
## Destination file path.
##
## @item @var{data}
## Data structure, array, or cell array to serialize.
## @end table
##
## @seealso{load_json, write_sample_jsonl}
## @end deftypefn
function save_json(filepath, data)
  json_str = jsonencode(data);
  % Create directory if it doesn't exist
  dir_path = fileparts(filepath);
  if !isempty(dir_path) && !exist(dir_path, "dir")
    mkdir(dir_path);
  endif
  fid = fopen(filepath, "w");
  if fid < 0
    error("Failed to write JSON file: %s", filepath);
  endif
  fprintf(fid, "%s\n", json_str);
  fclose(fid);
endfunction
