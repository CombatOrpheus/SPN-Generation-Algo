#include <octave/oct.h>
#include <octave/Cell.h>
#include <vector>

DEFUN_DLD(compute_average_markings_oct, args, nargout,
          "Compute average token counts and marginal token distributions per place.\n"
          "Syntax: [avg_markings, marking_densities] = compute_average_markings_oct(vertices, probs, P)") {

    if (args.length() < 3) {
        print_usage();
        return octave_value_list();
    }

    const int32NDArray vertices = args(0).int32_array_value();
    const NDArray probs = args(1).array_value();
    const int P = args(2).int_value();
    const int V = vertices.rows();

    if (V <= 0 || P <= 0) {
        return ovl(ColumnVector(0), Cell(dim_vector(0, 1)));
    }

    const octave_int32* raw_vertices = vertices.data();
    const double* raw_probs = probs.data();

    ColumnVector avg_markings(P, 0.0);
    std::vector<int> max_tokens(P, 0);

    // Pass 1: Compute expected value E[M(p)] and determine max observed tokens per place
    // Column-major sequential scanning along columns
    for (int p = 0; p < P; ++p) {
        const octave_int32* col = raw_vertices + p * V;
        double sum_tok = 0.0;
        int max_t = 0;
        for (int v = 0; v < V; ++v) {
            int tok = col[v].value();
            sum_tok += static_cast<double>(tok) * raw_probs[v];
            if (tok > max_t) {
                max_t = tok;
            }
        }
        avg_markings(p) = sum_tok;
        max_tokens[p] = max_t;
    }

    // Pass 2: Accumulate discrete marginal probability densities P(M(p) = k)
    Cell marking_densities(dim_vector(P, 1));
    for (int p = 0; p < P; ++p) {
        int max_t = max_tokens[p];
        RowVector dens(max_t + 1, 0.0);
        const octave_int32* col = raw_vertices + p * V;
        for (int v = 0; v < V; ++v) {
            int tok = col[v].value();
            if (tok >= 0 && tok <= max_t) {
                dens(tok) += raw_probs[v];
            }
        }
        marking_densities(p) = dens;
    }

    return ovl(avg_markings, marking_densities);
}
