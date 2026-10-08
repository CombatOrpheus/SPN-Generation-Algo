# Agent Instructions for SPN-Generation-Algo

This document provides instructions for AI agents working with this repository.

## Project Overview

This repository contains an Octave implementation of an algorithm for generating benchmark datasets of Stochastic Petri Nets (SPNs), maintaining full architectural parity with `SPN-Algo-Go`. It features C++ `oct` extensions for high performance, POSIX `fork`/`waitpid` parallel generation, and CTMC analysis.

### Modern Project Structure

- **`main.m`**: Command-line entry point supporting arguments (`--config`, `--mode`, `--samples`, `--workers`, `--seed`, `--output`, `--exact`).
- **`config.json`**: Default dataset generation configuration.
- **`setup_paths.m`**: Search path initialization for libraries, test helpers, and compiled extensions.
- **`src/`**: Modular core libraries:
  - `native/`: High-performance C++ `oct` extensions (`petrinet_prune_oct.cc`, `generate_reachability_graph_oct.cc`, `hash_marking_64_oct.cc`, `solve_steady_state_oct.cc`, `compute_average_markings_oct.cc`, `export_dataset_hdf5_oct.cc`, `import_dataset_hdf5_oct.cc`).
  - `petrinet/`: Net representation, bipartite connectivity BFS, token assignment, and pruning wrapper.
  - `generation/`: BFS reachability graph generator and parallel multiprocessing generation (`generate_parallel_dataset.m`).
  - `analysis/`: Infinitesimal CTMC generator matrix, steady-state solving (direct LU and sparse uniformization iterative power iteration), and place marking densities.
  - `augmentation/`: Net structure and transition firing rate variations.
  - `grid/`: 2D stratified partitioning across place and state-space boundaries.
  - `report/`: Dataset summary statistics, frequentist analysis (`analyze_dataset.m`), and HTML visual report generation.
  - `utils/`: JSON configuration, default configuration schemas, HDF5, and JSONL streaming serializers.
- **`tests/`**: Modular test suites and shared test fixtures (`tests/helpers/`) executed via `tests/run_tests.m` or `./dev.sh test`.
- **`benchmarks/`**: Microbenchmarks and 1000-net scaling benchmarks matching `SPN-Algo-Go`.
- **`Makefile`**: Portable build script compiling C++ `.oct` files from `src/native/` into `build/oct/`.
- **`dev.sh`**: Helper script managing Docker/Podman containers and test/build workflows.


## Environment Setup

A containerized environment is provided via `./dev.sh` (supporting Docker and Podman):

```bash
./dev.sh build   # Build dev container image
./dev.sh make    # Compile C++ oct-files via mkoctfile
./dev.sh test    # Run full test suite
```

Alternatively, on Debian/Ubuntu with native Octave:
```bash
sudo apt-get update && sudo apt-get install -y octave liboctave-dev gnuplot
make
```

## Running Tests

To run the full modern test suite:
```bash
./dev.sh test
# or inside Octave:
tests/run_tests
```


## Agent Workflow

1. **Maintain Architecture & Parity**: Preserve consistency with `SPN-Algo-Go` data structures and algorithmic behavior.
2. **Build and Test**: Always verify changes by running `./dev.sh make` and `./dev.sh test`.
3. **Preserve Documentation**: Ensure all Octave functions and C++ source files have clear docstrings and comments.
4. **Follow Octave/C++ Conventions**: Adhere to idiomatic GNU Octave code style and safe vectorization practices.