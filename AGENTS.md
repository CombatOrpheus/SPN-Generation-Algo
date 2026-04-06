# Agent Instructions for SPN-Generation-Algo

This document provides instructions for AI agents working with this repository.

## Project Overview

This repository contains an Octave implementation of an algorithm for generating datasets of Stochastic Petri Nets (SPNs). The primary goal is to create a benchmark dataset for learning algorithms. The code is structured as a series of Octave functions that handle the generation, filtering, and analysis of SPNs.

### Key Scripts

- **`generate_dataset.m`**: The main script for generating a complete dataset. It orchestrates the entire process, from random SPN creation to filtering and saving the results.
- **`spn_generate_random.m`**: Generates a single random SPN with a specified number of places and transitions.
- **`filter_spn.m`**: Analyzes an SPN to determine if it meets certain criteria (e.g., boundedness, connectivity) and is suitable for inclusion in the dataset.
- **`get_reachability_graph.m`**: A core analysis function that computes the reachability graph for a given SPN. This is crucial for checking properties like boundedness.
- **`test_suite.m`**: A test script that runs a series of checks to ensure the core functionalities of the repository are working correctly.

### `private/` Directory

The `private/` directory contains helper functions used by the main scripts. These are not meant to be called directly by the user but are essential for the internal workings of the tools.

## Environment Setup

This project requires **Octave** and the **gnuplot** package for plotting.

To set up the environment, run the following commands:

```bash
sudo apt-get update
sudo apt-get install -y octave gnuplot
```

## Performance Benchmarks

To ensure future optimizations are measurable, a benchmark suite is available to profile CPU time and peak memory (Maximum Resident Set Size).

### Running the Benchmark Suite
The benchmark suite scripts profile three key areas of the application:
1. **Generation:** Runs `bench_generation.m`
2. **Filtering:** Runs `bench_filtering.m`
3. **Solving:** Runs `bench_solving.m`

You can run the suite via the shell script:
```bash
./run_benchmark_suite.sh
```

### Initial Baselines
These baselines serve as a starting point for measuring the impact of subsequent optimizations.

- **Generation Phase** (100 SPNs):
  - Peak Memory (Max RSS): ~75.68 MB
  - Wall Clock Time: ~0:00.84

- **Filtering Phase** (50 SPNs):
  - Peak Memory (Max RSS): ~79.20 MB
  - Wall Clock Time: ~0:37.50

- **Solving Phase** (100 states target, using `bicg`):
  - Peak Memory (Max RSS): ~204.32 MB
  - Wall Clock Time: ~0:02.66

## Agent Workflow

1.  **Understand the Goal**: The primary purpose of this codebase is to generate SPN datasets. Most tasks will revolve around modifying the generation algorithm, improving performance, or adding new analysis features.
2.  **Consult the Documentation**: All functions, both public and private, should have comprehensive docstrings explaining their purpose, parameters, and return values. Refer to these docstrings to understand the functionality of each script.
3.  **Run Tests**: Before making changes, run the test suite to ensure the current implementation is working as expected. After making changes, run the tests again to check for regressions.

    To run the tests, start Octave and run the `test_suite` script:

    ```octave
    test_suite
    ```

4.  **Follow Octave Conventions**: Adhere to the standard coding style and documentation conventions for Octave. Ensure that any new code is clearly commented and documented.