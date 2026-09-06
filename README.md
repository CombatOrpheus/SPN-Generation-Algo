# Stochastic Petri Net (SPN) Generation Toolkit

Implementation of the Stochastic Petri Net (SPN) generation, analysis, and dataset benchmarking algorithm in GNU Octave, featuring C++ `oct` acceleration, parallel multiprocessing, and full architectural parity with `SPN-Algo-Go`.

## Modern Architecture & High-Performance Generator

The modular implementation is located in `src/` with entry point `main.m` and configuration in `config.json`:

*   **`src/petrinet`**: Petri net generation, bipartite connectivity validation, random token addition, and accelerated structural pruning (`petrinet_prune_oct.cc`).
*   **`src/generation`**: Reachability graph exploration with 64-bit marking hashing (`hash_marking_64_oct.cc`), BFS state-space exploration (`generate_reachability_graph_oct.cc`), and POSIX `fork`/`waitpid` parallel generation (`generate_parallel_dataset.m`).
*   **`src/analysis`**: CTMC infinitesimal generator computation, steady-state probability solving (exact direct LU and sparse uniformization iterative solver), and average place markings.
*   **`src/augmentation`**: Net structure and transition firing rate ($\lambda$) perturbation.
*   **`src/grid`**: 2D stratified grid partitioning across place count and state-space boundaries.
*   **`src/report`**: Aggregate dataset statistics and interactive HTML report generation.
*   **`src/utils`**: JSON configuration and JSONL streaming serialization.

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
    ./dev.sh octave --eval "main"
    # or with CLI flags:
    ./dev.sh octave --eval "main('--config', 'config.json', '--workers', 'auto', '--samples', '100')"
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

---

## Legacy Scripts (Standalone)

For backward compatibility with initial iterations, standalone scripts are preserved at the repository root:
- `generate_dataset.m`: Legacy dataset generator producing HDF5 `.h5` files.
- `spn_generate_random.m`: Single SPN generation.
- `filter_spn.m`: Property filtering.
- `get_reachability_graph.m`: Basic reachability graph computation.
- `test_suite.m`: Legacy test suite.