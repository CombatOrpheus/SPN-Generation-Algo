OUT_DIR = build/oct

OCTS = $(OUT_DIR)/generate_reachability_graph_oct.oct \
       $(OUT_DIR)/hash_marking_64_oct.oct \
       $(OUT_DIR)/petrinet_prune_oct.oct

all: $(OUT_DIR) $(OCTS)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/generate_reachability_graph_oct.oct: src/generation/generate_reachability_graph_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

$(OUT_DIR)/hash_marking_64_oct.oct: src/generation/hash_marking_64_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

$(OUT_DIR)/petrinet_prune_oct.oct: src/petrinet/petrinet_prune_oct.cc | $(OUT_DIR)
	mkoctfile -O3 $< -o $@

clean:
	rm -rf build/

.PHONY: all clean
