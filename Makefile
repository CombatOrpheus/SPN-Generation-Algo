OUT_DIR = build/oct
SRC_DIR = src/native

# Portable HDF5 compiler and linker flags:
# 1. Try pkg-config for standard hdf5 or hdf5-serial
# 2. Check Debian/Ubuntu serial paths
# 3. Fall back to standard default -lhdf5
HDF5_CFLAGS ?= $(shell pkg-config --cflags hdf5 2>/dev/null || pkg-config --cflags hdf5-serial 2>/dev/null || if [ -d /usr/include/hdf5/serial ]; then echo "-I/usr/include/hdf5/serial"; fi)
HDF5_LDFLAGS ?= $(shell pkg-config --libs hdf5 2>/dev/null || pkg-config --libs hdf5-serial 2>/dev/null || if [ -d /usr/lib/x86_64-linux-gnu/hdf5/serial ]; then echo "-L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5"; else echo "-lhdf5"; fi)

SIMD_CFLAGS ?= -march=native -fopenmp-simd -ffp-contract=fast

OCTS = $(OUT_DIR)/generate_reachability_graph_oct.oct \
       $(OUT_DIR)/hash_marking_64_oct.oct \
       $(OUT_DIR)/petrinet_prune_oct.oct \
       $(OUT_DIR)/export_dataset_hdf5_oct.oct \
       $(OUT_DIR)/import_dataset_hdf5_oct.oct \
       $(OUT_DIR)/solve_steady_state_oct.oct \
       $(OUT_DIR)/compute_average_markings_oct.oct

all: $(OUT_DIR) $(OCTS)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Specialized targets requiring external HDF5 libraries
$(OUT_DIR)/export_dataset_hdf5_oct.oct: $(SRC_DIR)/export_dataset_hdf5_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $(SIMD_CFLAGS) $(HDF5_CFLAGS) $(HDF5_LDFLAGS) $< -o $@

$(OUT_DIR)/import_dataset_hdf5_oct.oct: $(SRC_DIR)/import_dataset_hdf5_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $(SIMD_CFLAGS) $(HDF5_CFLAGS) $(HDF5_LDFLAGS) $< -o $@

# Pattern rule for standard C++ oct-files without external dependencies
$(OUT_DIR)/%_oct.oct: $(SRC_DIR)/%_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $(SIMD_CFLAGS) $< -o $@

clean:
	rm -rf build/
	find src -type f \( -name "*.oct" -o -name "*.o" \) -delete

test: all
	octave --no-gui -q tests/run_tests.m

bench: all
	octave --no-gui -q benchmarks/run_benchmarks.m

.PHONY: all clean test bench
