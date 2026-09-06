function save_json(filepath, data)
  % SAVE_JSON Encode and save data to a JSON file.
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
