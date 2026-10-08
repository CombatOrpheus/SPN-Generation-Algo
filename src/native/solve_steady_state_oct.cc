#include <octave/oct.h>
#include <vector>
#include <cmath>
#include <algorithm>

DEFUN_DLD(solve_steady_state_oct, args, nargout,
          "Solve for steady-state distribution using sparse uniformization power iteration.\n"
          "Syntax: [probs, err] = solve_steady_state_oct(edges, arc_transitions, lambda_values, num_vertices, max_iter, tol)") {

    if (args.length() < 4) {
        print_usage();
        return octave_value_list();
    }

    const int32NDArray edges = args(0).int32_array_value();
    const int32NDArray arc_transitions = args(1).int32_array_value();
    const NDArray lambda_values = args(2).array_value();
    const int V = args(3).int_value();

    int max_iter = 50000;
    if (args.length() >= 5 && !args(4).isempty()) {
        max_iter = args(4).int_value();
    }

    double tol = 1e-10;
    if (args.length() >= 6 && !args(5).isempty()) {
        tol = args(5).double_value();
    }

    // Boundary conditions
    if (V <= 0) {
        return ovl(ColumnVector(0), false);
    }
    if (V == 1) {
        ColumnVector single_p(1, 1.0);
        return ovl(single_p, false);
    }

    const octave_idx_type E = edges.rows();
    if (E == 0) {
        ColumnVector unif(V, 1.0 / static_cast<double>(V));
        return ovl(unif, false);
    }

    const octave_int32* raw_edges = edges.data();
    const octave_int32* raw_trans = arc_transitions.data();
    const double* raw_lambdas = lambda_values.data();
    const int num_transitions = lambda_values.numel();

    // 1. Calculate exit rates q_i per state (excluding self-loops) and incoming degree per state
    std::vector<double> q(V, 0.0);
    std::vector<int32_t> in_degree(V, 0);

    for (octave_idx_type i = 0; i < E; ++i) {
        int32_t src = raw_edges[i].value() - 1;
        int32_t dest = raw_edges[i + E].value() - 1;

        if (src >= 0 && src < V && dest >= 0 && dest < V && src != dest) {
            int32_t t_idx = raw_trans[i].value() - 1;
            if (t_idx >= 0 && t_idx < num_transitions) {
                double rate = raw_lambdas[t_idx];
                q[src] += rate;
                in_degree[dest]++;
            }
        }
    }

    double max_q = 0.0;
    for (int i = 0; i < V; ++i) {
        if (q[i] > max_q) {
            max_q = q[i];
        }
    }

    if (max_q == 0.0) {
        ColumnVector unif(V, 1.0 / static_cast<double>(V));
        return ovl(unif, false);
    }

    const double gamma = 1.01 * max_q;

    // 2. Build Compressed Sparse Row (CSR) representation for incoming transitions (PT)
    // row_ptr[j] points to incoming edges for destination vertex j
    std::vector<int32_t> row_ptr(V + 1, 0);
    for (int i = 0; i < V; ++i) {
        row_ptr[i + 1] = row_ptr[i] + in_degree[i];
    }
    const int total_active = row_ptr[V];
    if (total_active == 0) {
        ColumnVector unif(V, 1.0 / static_cast<double>(V));
        return ovl(unif, false);
    }

    std::vector<int32_t> col_indices(total_active);
    std::vector<double> edge_rates(total_active);
    std::vector<int32_t> cursor = row_ptr;

    for (octave_idx_type i = 0; i < E; ++i) {
        int32_t src = raw_edges[i].value() - 1;
        int32_t dest = raw_edges[i + E].value() - 1;

        if (src >= 0 && src < V && dest >= 0 && dest < V && src != dest) {
            int32_t t_idx = raw_trans[i].value() - 1;
            if (t_idx >= 0 && t_idx < num_transitions) {
                int pos = cursor[dest]++;
                col_indices[pos] = src;
                edge_rates[pos] = raw_lambdas[t_idx] / gamma;
            }
        }
    }

    // Precompute diagonal multipliers
    std::vector<double> diag_mult(V);
    #pragma omp simd
    for (int i = 0; i < V; ++i) {
        diag_mult[i] = 1.0 - (q[i] / gamma);
    }

    // 3. Uniform initialization: pi_0 = 1 / V
    std::vector<double> pi(V, 1.0 / static_cast<double>(V));
    std::vector<double> pi_next(V, 0.0);
    std::vector<double> pi_prev(V);

    bool converged = false;
    const int batch_size = 15;

    // 4. Batched Power Iteration using CSR incoming dot-product (SIMD-vectorized)
    for (int iter = 0; iter < max_iter; iter += batch_size) {
        pi_prev = pi;
        int steps = std::min(batch_size, max_iter - iter);

        for (int s = 0; s < steps; ++s) {
            for (int j = 0; j < V; ++j) {
                double in_flow = 0.0;
                const int start = row_ptr[j];
                const int end = row_ptr[j + 1];

                #pragma omp simd reduction(+:in_flow)
                for (int k = start; k < end; ++k) {
                    in_flow += pi[col_indices[k]] * edge_rates[k];
                }
                pi_next[j] = pi[j] * diag_mult[j] + in_flow;
            }
            pi.swap(pi_next);
        }

        // Periodic normalization against numerical drift
        double sum = 0.0;
        #pragma omp simd reduction(+:sum)
        for (int i = 0; i < V; ++i) {
            sum += pi[i];
        }
        if (sum > 0.0) {
            double inv_sum = 1.0 / sum;
            #pragma omp simd
            for (int i = 0; i < V; ++i) {
                pi[i] *= inv_sum;
            }
        }

        // L1 convergence check across the batch
        double diff = 0.0;
        #pragma omp simd reduction(+:diff)
        for (int i = 0; i < V; ++i) {
            diff += std::abs(pi[i] - pi_prev[i]);
        }
        if (diff < tol) {
            converged = true;
            break;
        }
    }

    // 5. Clamping and final normalization
    ColumnVector probs(V);
    double prob_sum = 0.0;
    for (int i = 0; i < V; ++i) {
        double p = pi[i];
        if (p < 0.0) p = 0.0;
        probs(i) = p;
        prob_sum += p;
    }

    bool err = !converged;
    if (prob_sum > 1e-9) {
        probs /= prob_sum;
    } else {
        err = true;
    }

    return ovl(probs, err);
}
