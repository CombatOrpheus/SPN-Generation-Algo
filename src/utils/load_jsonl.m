function items = load_jsonl(filepath)
  % LOAD_JSONL Reads a JSONL file and decodes each line into a cell array of structs.
  %
  % Preallocates cell array in chunks to avoid single-element organic expansion.

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
