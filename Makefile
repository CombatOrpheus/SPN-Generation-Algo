OCTS = src/generation/generate_reachability_graph_oct.oct \
       src/generation/hash_marking_64_oct.oct \
       src/petrinet/petrinet_prune_oct.oct

all: $(OCTS)

src/generation/generate_reachability_graph_oct.oct: src/generation/generate_reachability_graph_oct.cc
	mkoctfile -O3 $< -o $@

src/generation/hash_marking_64_oct.oct: src/generation/hash_marking_64_oct.cc
	mkoctfile -O3 $< -o $@

src/petrinet/petrinet_prune_oct.oct: src/petrinet/petrinet_prune_oct.cc
	mkoctfile -O3 $< -o $@

clean:
	rm -f src/generation/*.o src/generation/*.oct src/petrinet/*.o src/petrinet/*.oct

.PHONY: all clean
