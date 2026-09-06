#include <octave/oct.h>
#include <octave/oct-map.h>
#include <vector>
#include <unordered_map>
#include <cstdint>
#include <algorithm>

// 64-bit avalanche hash matching SPN-Algo-Go
static inline uint64_t hash_marking(const std::vector<int32_t>& m) {
    uint64_t h = 0x517cc1b727220a95ULL;
    for (int32_t v : m) {
        h = (h ^ static_cast<uint64_t>(v)) * 0xbf58476d1ce4e5b9ULL;
        h = (h ^ (h >> 30)) * 0x94d049bb133111ebULL;
    }
    return h ^ (h >> 31);
}

DEFUN_DLD(generate_reachability_graph_oct, args, nargout,
          "Generate reachability graph of a Petri net using BFS.\n"
          "Syntax: rg = generate_reachability_graph_oct(matrix, P, T, initial_marking, place_upper_limit, max_markings)") {

    if (args.length() < 6) {
        print_usage();
        return octave_value_list();
    }

    const int32NDArray matrix_arg = args(0).int32_array_value();
    const int P = args(1).int_value();
    const int T = args(2).int_value();
    const int32NDArray init_m_arg = args(3).int32_array_value();
    const int place_upper_limit = args(4).int_value();
    const int max_markings = args(5).int_value();

    // Extract pre-requirements and token changes
    // Matrix in Octave is column-major: matrix(row, col)
    // col 0..T-1: Pre, col T..2T-1: Post
    struct SparseReq {
        int place;
        int tokens;
    };
    struct SparseChange {
        int place;
        int delta;
    };

    std::vector<std::vector<SparseReq>> pre_reqs(T);
    std::vector<std::vector<SparseChange>> changes(T);

    for (int t = 0; t < T; t++) {
        for (int p = 0; p < P; p++) {
            int pre = matrix_arg(p, t);
            int post = matrix_arg(p, t + T);
            int delta = post - pre;

            if (pre > 0) {
                pre_reqs[t].push_back({p, pre});
            }
            if (delta != 0) {
                changes[t].push_back({p, delta});
            }
        }
    }

    std::vector<int32_t> initial_marking(P);
    for (int p = 0; p < P; p++) {
        initial_marking[p] = init_m_arg(p);
    }

    // Reachability graph structures
    std::vector<std::vector<int32_t>> vertices;
    vertices.push_back(initial_marking);

    std::vector<std::pair<int, int>> edges; // 1-based vertex indices
    std::vector<int> arc_transitions;        // 1-based transition indices

    // Visited map: hash -> list of vertex indices (to handle collisions)
    std::unordered_map<uint64_t, std::vector<int>> visited;
    visited[hash_marking(initial_marking)].push_back(1); // 1-based index

    std::vector<int> queue;
    queue.push_back(1); // 1-based index
    size_t head = 0;

    bool is_bounded = true;
    std::vector<int32_t> scratch_marking(P);

    while (head < queue.size()) {
        int current_idx = queue[head++];

        if (static_cast<int>(vertices.size()) >= max_markings) {
            is_bounded = false;
            break;
        }

        for (int t = 0; t < T; t++) {
            bool is_enabled = true;
            for (const auto& req : pre_reqs[t]) {
                if (vertices[current_idx - 1][req.place] < req.tokens) {
                    is_enabled = false;
                    break;
                }
            }

            if (is_enabled) {
                bool out_of_bounds = false;
                scratch_marking = vertices[current_idx - 1];

                for (const auto& chg : changes[t]) {
                    int tokens = scratch_marking[chg.place] + chg.delta;
                    if (tokens > place_upper_limit) {
                        out_of_bounds = true;
                        break;
                    }
                    scratch_marking[chg.place] = tokens;
                }

                if (out_of_bounds) {
                    is_bounded = false;
                    break;
                }

                uint64_t h = hash_marking(scratch_marking);
                int matched_vertex = -1;

                auto it = visited.find(h);
                if (it != visited.end()) {
                    for (int cand_idx : it->second) {
                        if (scratch_marking == vertices[cand_idx - 1]) {
                            matched_vertex = cand_idx;
                            break;
                        }
                    }
                }

                if (matched_vertex == -1) {
                    int new_vertex_idx = static_cast<int>(vertices.size()) + 1; // 1-based
                    visited[h].push_back(new_vertex_idx);
                    vertices.push_back(scratch_marking);
                    queue.push_back(new_vertex_idx);

                    edges.push_back({current_idx, new_vertex_idx});
                } else {
                    edges.push_back({current_idx, matched_vertex});
                }
                arc_transitions.push_back(t + 1); // 1-based transition index
            }
        }

        if (!is_bounded) {
            break;
        }
    }

    // Build return struct using octave_scalar_map
    octave_scalar_map rg;
    int num_v = static_cast<int>(vertices.size());
    int num_e = static_cast<int>(edges.size());

    // Vertices matrix: num_v x P (column-major contiguous write)
    int32NDArray out_vertices(dim_vector(num_v, P));
    auto* v_ptr = out_vertices.fortran_vec();
    for (int p = 0; p < P; p++) {
        for (int i = 0; i < num_v; i++) {
            v_ptr[i + p * num_v] = vertices[i][p];
        }
    }

    // Edges matrix: num_e x 2 (column-major contiguous write)
    int32NDArray out_edges(dim_vector(num_e, 2));
    auto* e_ptr = out_edges.fortran_vec();
    for (int i = 0; i < num_e; i++) {
        e_ptr[i] = edges[i].first;
        e_ptr[i + num_e] = edges[i].second;
    }

    // Arc transitions: num_e x 1 (column-major contiguous write)
    int32NDArray out_arc_trans(dim_vector(num_e, 1));
    auto* a_ptr = out_arc_trans.fortran_vec();
    for (int i = 0; i < num_e; i++) {
        a_ptr[i] = arc_transitions[i];
    }



    rg.setfield("vertices", octave_value(out_vertices));
    rg.setfield("edges", octave_value(out_edges));
    rg.setfield("arc_transitions", octave_value(out_arc_trans));
    rg.setfield("num_vertices", octave_value(num_v));
    rg.setfield("num_edges", octave_value(num_e));
    rg.setfield("is_bounded", octave_value(is_bounded));

    return octave_value_list(octave_value(rg));
}
