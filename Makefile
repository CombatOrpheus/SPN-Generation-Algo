OUT_DIR = build/oct

HDF5_CFLAGS ?= -I/usr/include/hdf5/serial
HDF5_LDFLAGS ?= -L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5

OCTS = $(OUT_DIR)/generate_reachability_graph_oct.oct \
       $(OUT_DIR)/hash_marking_64_oct.oct \
       $(OUT_DIR)/petrinet_prune_oct.oct \
       $(OUT_DIR)/export_dataset_hdf5_oct.oct \
       $(OUT_DIR)/import_dataset_hdf5_oct.oct

all: $(OUT_DIR) $(OCTS)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/generate_reachability_graph_oct.oct: src/generation/generate_reachability_graph_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

$(OUT_DIR)/hash_marking_64_oct.oct: src/generation/hash_marking_64_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

$(OUT_DIR)/petrinet_prune_oct.oct: src/petrinet/petrinet_prune_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

$(OUT_DIR)/export_dataset_hdf5_oct.oct: src/utils/export_dataset_hdf5_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $(HDF5_CFLAGS) $(HDF5_LDFLAGS) $< -o $@

$(OUT_DIR)/import_dataset_hdf5_oct.oct: src/utils/import_dataset_hdf5_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $(HDF5_CFLAGS) $(HDF5_LDFLAGS) $< -o $@

clean:
	rm -rf build/

.PHONY: all clean
