# Stochastic Petri Net (SPN) Generation Toolkit

This repository provides a set of functions written in Octave for generating, analyzing, and filtering Stochastic Petri Nets (SPNs). It is primarily designed to create benchmark datasets for SPN learning algorithms, as described in the paper "The Benchmark Datasets for Stochastic Petri Net Learning."

This implementation was developed as a learning exercise to better understand the algorithm's mechanics and to explore potential performance improvements over the original Python-based reference implementation.

## Features

-   **SPN Generation**: Create random SPNs with a specified number of places and transitions.
-   **Reachability Analysis**: Compute the reachability graph to determine all possible states of an SPN.
-   **Property Filtering**: Automatically filter SPNs based on properties like boundedness and connectivity.
-   **Dataset Creation**: Systematically generate and save large datasets of valid SPNs organized into bins based on their characteristics.

## Getting Started

### Prerequisites

To use this toolkit, you will need to have **Octave** installed on your system. For some visualization and plotting functions, **gnuplot** is also required.

-   **Octave**: A high-level language, primarily intended for numerical computations. You can download it from the [official GNU Octave website](https://www.gnu.org/software/octave/download.html).
-   **Gnuplot**: A command-line-driven graphing utility.

### Installation on Debian/Ubuntu

You can install the necessary packages using `apt`:

```bash
sudo apt-get update
sudo apt-get install -y octave gnuplot
```

### Usage

The two main entry points for this toolkit are `generate_dataset.m` for creating a full dataset and `test_spn.m` for verifying the installation.

#### Running the Tests

To ensure everything is set up correctly, you can run the built-in test suite. The tests will execute the core functions and perform basic checks to confirm they are working as expected.

1.  Launch Octave from your terminal:
    ```bash
    octave
    ```
2.  From the Octave prompt, run the test script:
    ```octave
    test_spn
    ```

You should see output indicating that all tests have passed.

#### Generating a Dataset

The `generate_dataset` function allows you to create a custom dataset of SPNs based on your specified parameters.

**Function Signature:**

```octave
generate_dataset(pn_range, tn_range, states_bins, spns_per_bin, output_dir)
```

-   `pn_range`: A `[min, max]` vector for the number of places.
-   `tn_range`: A `[min, max]` vector for the number of transitions.
-   `states_bins`: A vector defining the boundaries for state bins (e.g., `[20, 100]`).
-   `spns_per_bin`: The number of valid SPNs to generate for each bin.
-   `output_dir`: The directory where the dataset will be saved.

**Example:**

To generate a small dataset with 5 SPNs per bin, for nets with 5-10 places and 4-8 transitions, binned by `<20`, `20-99`, and `>=100` states, you would run the following in Octave:

```octave
generate_dataset([5, 10], [4, 8], [20, 100], 5, 'my_spn_dataset');
```

This will create a directory named `my_spn_dataset` containing the generated SPN files in HDF5 format and a `metadata.csv` file with a summary of the dataset.

## Project Structure

-   **`.m` files (root)**: These are the main, user-facing functions.
-   **`private/`**: Contains helper functions that are used internally by the main scripts. These are not intended to be called directly.
-   **`test_dataset/`**: A sample directory structure for where a generated dataset might be stored.
-   **`AGENTS.md`**: Provides instructions and context for AI agents working with this codebase.