# Stochastic Petri Net (SPN) Generation Toolkit

Implementation of the Stochastic Petri Net (SPN) generation, analysis, and dataset benchmarking algorithm in GNU Octave, featuring C++ `oct` acceleration, parallel multiprocessing, and full architectural parity with `SPN-Algo-Go`.

## Modern Architecture & High-Performance Generator

The modular implementation is located in `src/` with entry point `main.m` and configuration in `config.json`:

*   **`src/native`**: High-performance C++ `oct` extensions compiled into `build/oct/` (`petrinet_prune_oct.cc`, `generate_reachability_graph_oct.cc`, `hash_marking_64_oct.cc`, `solve_steady_state_oct.cc`, `compute_average_markings_oct.cc`, `export_dataset_hdf5_oct.cc`, `import_dataset_hdf5_oct.cc`).
*   **`src/petrinet`**: Petri net generation, bipartite connectivity validation, random token addition, structural pruning, and high-level classdef wrapper (`PetriNet.m`).
*   **`src/generation`**: Reachability graph exploration, classdef wrapper (`ReachabilityGraph.m`), and POSIX `fork`/`waitpid` parallel multiprocessing generation (`generate_parallel_dataset.m`).
*   **`src/analysis`**: CTMC infinitesimal generator computation, steady-state probability solving (exact direct LU and sparse uniformization iterative solver), and average place markings.
*   **`src/augmentation`**: Net structure and transition firing rate ($\lambda$) perturbation.
*   **`src/grid`**: 2D stratified grid partitioning across place count and state-space boundaries.
*   **`src/report`**: Aggregate dataset statistics, dataset inspection (`analyze_dataset.m`), and interactive HTML report generation.
*   **`src/utils`**: JSON configuration, canonical defaults (`get_default_config.m`), HDF5, and JSONL streaming serialization.

> **Note**: The core dataset generator and multiprocessing pipeline operate on vectorized flat `struct` representations for zero-allocation performance, with `PetriNet.m` and `ReachabilityGraph.m` providing object-oriented convenience wrappers.

---

## Containerized Development Environment (Docker / Podman)

A containerized development environment is provided via `./dev.sh` with GNU Octave 11.3.0, `mkoctfile` C/C++ compiler tools, and non-root user mapping.

### Using the Helper Script (`dev.sh`)

*   **Build the dev image**:
    ```bash
    ./dev.sh build
    ```

*   **Compile C++ Oct-files**:
    ```bash
    ./dev.sh make
    ```

*   **Run test suites**:
    ```bash
    ./dev.sh test
    ```

*   **Run the dataset generator**:
    ```bash
    ./dev.sh run --samples 100
    # or with full options:
    ./dev.sh run --config config.json --workers auto --samples 100 --output output.jsonl
    ```

*   **Run benchmarks**:
    ```bash
    ./dev.sh octave --eval "addpath('benchmarks'); run_benchmarks;"
    ```

*   **Open interactive container shell**:
    ```bash
    ./dev.sh shell
    ```

---

## CLI Options (`main.m`)

The main CLI generator supports the following flags:
*   `--config <path>`: Path to JSON configuration file (default: `config.json`).
*   `--mode <mode>`: Generation mode: `'random'` or `'grid'`.
*   `--samples <N>`: Number of samples to generate.
*   `--output <path>`: Output JSONL destination path.
*   `--workers, -j <N>`: Parallel workers (`'auto'` or integer, default: `'auto'`).
*   `--seed <N>`: RNG seed for reproducible generation.
*   `--exact` / `--no-exact`: Ensure exact target sample count via retries (default: `--exact`).
