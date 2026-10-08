#include <octave/oct.h>
#include <vector>
#include <random>
#include <algorithm>

static bool is_connected_bipartite(const int32NDArray& mat, int P, int T) {
    if (P == 0 || T == 0) return true;

    std::vector<bool> visited_places(P, false);
    std::vector<bool> visited_trans(T, false);

    std::vector<int> place_queue;
    place_queue.reserve(P);
    std::vector<int> trans_queue;
    trans_queue.reserve(T);

    visited_places[0] = true;
    place_queue.push_back(0);

    int visited_p_count = 1;
    int visited_t_count = 0;
    size_t p_head = 0;
    size_t t_head = 0;

    while (p_head < place_queue.size() || t_head < trans_queue.size()) {
        if (p_head < place_queue.size()) {
            int p = place_queue[p_head++];
            for (int t = 0; t < T; t++) {
                if (!visited_trans[t] && (mat(p, t).value() > 0 || mat(p, t + T).value() > 0)) {
                    visited_trans[t] = true;
                    visited_t_count++;
                    trans_queue.push_back(t);
                }
            }
        }
        if (t_head < trans_queue.size()) {
            int t = trans_queue[t_head++];
            for (int p = 0; p < P; p++) {
                if (!visited_places[p] && (mat(p, t).value() > 0 || mat(p, t + T).value() > 0)) {
                    visited_places[p] = true;
                    visited_p_count++;
                    place_queue.push_back(p);
                }
            }
        }
    }

    return (visited_p_count == P) && (visited_t_count == T);
}

DEFUN_DLD(petrinet_prune_oct, args, nargout,
          "Prune Petri net matrix using fast C++ implementation.\n"
          "Syntax: pruned_matrix = petrinet_prune_oct(matrix, P, T)") {

    if (args.length() < 3) {
        print_usage();
        return octave_value_list();
    }

    int32NDArray mat = args(0).int32_array_value();
    const int P = args(1).int_value();
    const int T = args(2).int_value();
    const int num_cols = 2 * T;

    // Random generator
    static std::random_device rd;
    static std::mt19937 g(rd());

    if (args.length() >= 4 && !args(3).isempty()) {
        g.seed(static_cast<uint32_t>(args(3).uint_value()));
    }

    auto* raw_mat = mat.fortran_vec();

    // 1. Compute initial row and column sums across arc columns 0..2*T-1
    // Column-major sequential access
    std::vector<int> row_sums(P, 0);
    std::vector<int> col_sums(num_cols, 0);

    for (int j = 0; j < num_cols; j++) {
        const int col_offset = j * P;
        for (int i = 0; i < P; i++) {
            int val = raw_mat[i + col_offset].value();
            if (val > 0) {
                row_sums[i] += val;
                col_sums[j] += val;
            }
        }
    }


    // 2. Delete excess edges from places (row_sum >= 3)
    std::vector<int> edge_indices;
    edge_indices.reserve(num_cols);

    for (int i = 0; i < P; i++) {
        if (row_sums[i] >= 3) {
            edge_indices.clear();
            for (int j = 0; j < num_cols; j++) {
                if (mat(i, j).value() == 1) {
                    edge_indices.push_back(j);
                }
            }
            std::shuffle(edge_indices.begin(), edge_indices.end(), g);
            int num_to_try = static_cast<int>(edge_indices.size()) - 2;
            for (int k = 0; k < num_to_try; k++) {
                int col_idx = edge_indices[k];
                if (col_sums[col_idx] > 1) {
                    mat(i, col_idx) = 0;
                    if (!is_connected_bipartite(mat, P, T)) {
                        mat(i, col_idx) = 1;
                    } else {
                        row_sums[i]--;
                        col_sums[col_idx]--;
                    }
                }
            }
        }
    }

    // 3. Delete excess edges from transitions (col_sum >= 3)
    edge_indices.reserve(P);
    for (int j = 0; j < num_cols; j++) {
        if (col_sums[j] >= 3) {
            edge_indices.clear();
            for (int i = 0; i < P; i++) {
                if (mat(i, j).value() == 1) {
                    edge_indices.push_back(i);
                }
            }
            std::shuffle(edge_indices.begin(), edge_indices.end(), g);
            int num_to_try = static_cast<int>(edge_indices.size()) - 2;
            for (int k = 0; k < num_to_try; k++) {
                int row_idx = edge_indices[k];
                if (row_sums[row_idx] > 1) {
                    mat(row_idx, j) = 0;
                    if (!is_connected_bipartite(mat, P, T)) {
                        mat(row_idx, j) = 1;
                    } else {
                        row_sums[row_idx]--;
                        col_sums[j]--;
                    }
                }
            }
        }
    }

    // 4. Add missing connections to transitions
    std::uniform_int_distribution<int> rand_place(0, P - 1);
    for (int j = 0; j < num_cols; j++) {
        if (col_sums[j] == 0) {
            int r = rand_place(g);
            mat(r, j) = 1;
            row_sums[r]++;
            col_sums[j]++;
        }
    }

    // 5. Add missing connections to places
    std::uniform_int_distribution<int> rand_trans(0, T - 1);
    for (int i = 0; i < P; i++) {
        // Pre-connections
        int pre_sum = 0;
        for (int j = 0; j < T; j++) {
            pre_sum += mat(i, j).value();
        }
        if (pre_sum == 0) {
            int r = rand_trans(g);
            mat(i, r) = 1;
            row_sums[i]++;
            col_sums[r]++;
        }

        // Post-connections
        int post_sum = 0;
        for (int j = T; j < num_cols; j++) {
            post_sum += mat(i, j).value();
        }
        if (post_sum == 0) {
            int r = T + rand_trans(g);
            mat(i, r) = 1;
            row_sums[i]++;
            col_sums[r]++;
        }
    }

    return octave_value_list(octave_value(mat));
}
