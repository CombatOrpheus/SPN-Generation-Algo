#!/bin/bash
# run_benchmark_suite.sh
# Runs a comprehensive benchmark suite for the SPN generation toolkit
# Captures CPU time and Peak Memory (Max RSS)

echo "=========================================="
echo "      SPN Toolkit Benchmark Suite         "
echo "=========================================="

# Function to run benchmark
run_bench() {
    name=$1
    script=$2

    echo ""
    echo "--- Benchmarking: $name ---"

    # Run under time -v
    # Send normal octave output to stdout, time -v output to a temporary file
    tmp_time_file=$(mktemp)

    # Use xvfb-run in case of graphics plotting
    /usr/bin/time -v -o "$tmp_time_file" xvfb-run octave --eval "$script"

    # Extract Max RSS and Wall time
    max_rss=$(grep "Maximum resident set size" "$tmp_time_file" | awk '{print $6}')
    wall_time=$(grep "Elapsed (wall clock) time" "$tmp_time_file" | awk '{print $8}')
    user_time=$(grep "User time" "$tmp_time_file" | awk '{print $4}')
    sys_time=$(grep "System time" "$tmp_time_file" | awk '{print $4}')

    # Convert Max RSS to MB
    max_rss_mb=$(echo "scale=2; $max_rss / 1024" | bc)

    echo "-> Metrics for $name:"
    echo "   Peak Memory (Max RSS): ${max_rss_mb} MB"
    echo "   Wall Clock Time: $wall_time"
    echo "   User Time: ${user_time}s"
    echo "   System Time: ${sys_time}s"

    rm "$tmp_time_file"
}

run_bench "Generation Phase" "bench_generation"
run_bench "Filtering Phase" "bench_filtering"
run_bench "Solving Phase" "bench_solving"

echo "=========================================="
echo "           Benchmark Complete             "
echo "=========================================="
