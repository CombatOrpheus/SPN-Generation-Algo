## -*- texinfo -*-
## @deftypefn {} {} setup_paths ()
## Initialize GNU Octave search paths for the SPN benchmark generation toolkit.
##
## Adds @file{src/}, @file{tests/}, and compiled @file{build/oct/} directories
## to the path, ensuring compiled C++ extensions take precedence.
##
## @seealso{main, run_tests}
## @end deftypefn
function setup_paths()
  root_dir = fileparts(mfilename("fullpath"));
  if isempty(root_dir)
    root_dir = pwd();
  endif

  % Add root directory
  addpath(root_dir);

  % Add src subdirectories
  src_dir = fullfile(root_dir, "src");
  if exist(src_dir, "dir")
    addpath(genpath(src_dir));
  endif

  % Add tests directory and helpers
  tests_dir = fullfile(root_dir, "tests");
  if exist(tests_dir, "dir")
    addpath(tests_dir);
    helpers_dir = fullfile(tests_dir, "helpers");
    if exist(helpers_dir, "dir")
      addpath(helpers_dir);
    endif
  endif

  % Add benchmarks directory
  bench_dir = fullfile(root_dir, "benchmarks");
  if exist(bench_dir, "dir")
    addpath(bench_dir);
  endif

  % Add compiled .oct directory at the front of the search path
  build_oct_dir = fullfile(root_dir, "build", "oct");
  if exist(build_oct_dir, "dir")
    addpath(build_oct_dir, "-begin");
  endif
endfunction
