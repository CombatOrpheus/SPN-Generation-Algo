# Agent Instructions for SPN-Generation-Algo

This document provides instructions for AI agents working with this repository.

## Project Overview

This repository contains an Octave implementation of an algorithm for generating benchmark datasets of Stochastic Petri Nets (SPNs), maintaining full architectural parity with `SPN-Algo-Go`. It features C++ `oct` extensions for high performance, POSIX `fork`/`waitpid` parallel generation, and CTMC analysis.

### Modern Project Structure

- **`main.m`**: Command-line entry point supporting arguments (`--config`, `--mode`, `--samples`, `--workers`, `--seed`, `--output`, `--exact`).
- **`config.json`**: Default dataset generation configuration.
- **`src/`**: Modular core libraries:
  - `petrinet/`: Net representation, bipartite connectivity BFS, token assignment, and C++ accelerated pruning (`petrinet_prune_oct.cc`).
  - `generation/`: BFS reachability graph generator with C++ oct acceleration (`generate_reachability_graph_oct.cc`), 64-bit marking hash (`hash_marking_64_oct.cc`), and parallel multiprocessing generation (`generate_parallel_dataset.m`).
  - `analysis/`: Infinitesimal CTMC generator matrix, steady-state solving (direct LU and sparse uniformization iterative power iteration), and place marking densities.
  - `augmentation/`: Net structure and transition firing rate variations.
  - `grid/`: 2D stratified partitioning across place and state-space boundaries.
  - `report/`: Dataset summary statistics and HTML visual report generation.
  - `utils/`: JSON configuration and JSONL streaming serializers.
- **`tests/`**: Modular test suites executed via `tests/run_tests.m` or `./dev.sh test`.
- **`benchmarks/`**: Microbenchmarks and 1000-net scaling benchmarks matching `SPN-Algo-Go`.
- **`Makefile`**: Builds C++ `.oct` files via `mkoctfile`.
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