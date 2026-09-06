function data = load_json(filepath)
  % LOAD_JSON Load and decode JSON from a file.
  fid = fopen(filepath, "r");
  if fid < 0
    error("Failed to open JSON file: %s", filepath);
  endif
  raw = fread(fid, "*char")';
  fclose(fid);
  data = jsondecode(raw);
endfunction
