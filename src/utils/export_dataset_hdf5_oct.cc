// export_dataset_hdf5_oct.cc - High-performance C++ HDF5 dataset exporter for SPN datasets
// Supports both 'flat' (CSR-style pointer indexing) and 'groups' (hierarchical) layouts,
// with chunked byte-shuffle and deflate compression.

#include <octave/oct.h>
#include <octave/Cell.h>
#include <octave/oct-map.h>
#include <hdf5/serial/hdf5.h>

#include <vector>
#include <string>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iostream>

// Helper to write an int32 attribute on a group or dataset
static void write_attr_int32(hid_t loc_id, const char* name, int32_t val) {
    hid_t space_id = H5Screate(H5S_SCALAR);
    hid_t attr_id = H5Acreate2(loc_id, name, H5T_NATIVE_INT32, space_id, H5P_DEFAULT, H5P_DEFAULT);
    if (attr_id >= 0) {
        H5Awrite(attr_id, H5T_NATIVE_INT32, &val);
        H5Aclose(attr_id);
    }
    H5Sclose(space_id);
}

// Helper to write a string attribute on a group or dataset
static void write_attr_string(hid_t loc_id, const char* name, const std::string& str) {
    hid_t type_id = H5Tcopy(H5T_C_S1);
    H5Tset_size(type_id, str.size() > 0 ? str.size() : 1);
    H5Tset_strpad(type_id, H5T_STR_NULLTERM);
    hid_t space_id = H5Screate(H5S_SCALAR);
    hid_t attr_id = H5Acreate2(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT);
    if (attr_id >= 0) {
        H5Awrite(attr_id, type_id, str.c_str());
        H5Aclose(attr_id);
    }
    H5Sclose(space_id);
    H5Tclose(type_id);
}

// Helper: Write 2D int32 array (Row-Major in HDF5 from Column-Major in Octave)
static bool write_int32_2d(hid_t loc_id, const char* name, const int32_t* data,
                           size_t rows, size_t cols, int comp_lvl) {
    hsize_t dims[2] = { (hsize_t)rows, (hsize_t)cols };
    hid_t space_id = H5Screate_simple(2, dims, NULL);
    hid_t plist_id = H5Pcreate(H5P_DATASET_CREATE);
    if (comp_lvl > 0 && rows > 0 && cols > 0) {
        hsize_t chunk[2] = { std::min((hsize_t)rows, (hsize_t)1024), (hsize_t)cols };
        H5Pset_chunk(plist_id, 2, chunk);
        H5Pset_shuffle(plist_id);
        H5Pset_deflate(plist_id, comp_lvl);
    }
    hid_t dset_id = H5Dcreate2(loc_id, name, H5T_NATIVE_INT32, space_id, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    H5Pclose(plist_id);
    H5Sclose(space_id);
    if (dset_id < 0) return false;

    herr_t status = 0;
    if (rows > 0 && cols > 0 && data != nullptr) {
        status = H5Dwrite(dset_id, H5T_NATIVE_INT32, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);
    }
    H5Dclose(dset_id);
    return (status >= 0);
}

// Helper: Write 1D int32 array
static bool write_int32_1d(hid_t loc_id, const char* name, const int32_t* data,
                           size_t len, int comp_lvl) {
    hsize_t dims[1] = { (hsize_t)len };
    hid_t space_id = H5Screate_simple(1, dims, NULL);
    hid_t plist_id = H5Pcreate(H5P_DATASET_CREATE);
    if (comp_lvl > 0 && len > 0) {
        hsize_t chunk[1] = { std::min((hsize_t)len, (hsize_t)8192) };
        H5Pset_chunk(plist_id, 1, chunk);
        H5Pset_shuffle(plist_id);
        H5Pset_deflate(plist_id, comp_lvl);
    }
    hid_t dset_id = H5Dcreate2(loc_id, name, H5T_NATIVE_INT32, space_id, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    H5Pclose(plist_id);
    H5Sclose(space_id);
    if (dset_id < 0) return false;

    herr_t status = 0;
    if (len > 0 && data != nullptr) {
        status = H5Dwrite(dset_id, H5T_NATIVE_INT32, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);
    }
    H5Dclose(dset_id);
    return (status >= 0);
}

// Helper: Write 2D double array (Row-Major in HDF5)
static bool write_double_2d(hid_t loc_id, const char* name, const double* data,
                            size_t rows, size_t cols, int comp_lvl) {
    hsize_t dims[2] = { (hsize_t)rows, (hsize_t)cols };
    hid_t space_id = H5Screate_simple(2, dims, NULL);
    hid_t plist_id = H5Pcreate(H5P_DATASET_CREATE);
    if (comp_lvl > 0 && rows > 0 && cols > 0) {
        hsize_t chunk[2] = { std::min((hsize_t)rows, (hsize_t)1024), (hsize_t)cols };
        H5Pset_chunk(plist_id, 2, chunk);
        H5Pset_shuffle(plist_id);
        H5Pset_deflate(plist_id, comp_lvl);
    }
    hid_t dset_id = H5Dcreate2(loc_id, name, H5T_NATIVE_DOUBLE, space_id, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    H5Pclose(plist_id);
    H5Sclose(space_id);
    if (dset_id < 0) return false;

    herr_t status = 0;
    if (rows > 0 && cols > 0 && data != nullptr) {
        status = H5Dwrite(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);
    }
    H5Dclose(dset_id);
    return (status >= 0);
}

// Helper: Write 1D double array
static bool write_double_1d(hid_t loc_id, const char* name, const double* data,
                            size_t len, int comp_lvl) {
    hsize_t dims[1] = { (hsize_t)len };
    hid_t space_id = H5Screate_simple(1, dims, NULL);
    hid_t plist_id = H5Pcreate(H5P_DATASET_CREATE);
    if (comp_lvl > 0 && len > 0) {
        hsize_t chunk[1] = { std::min((hsize_t)len, (hsize_t)8192) };
        H5Pset_chunk(plist_id, 1, chunk);
        H5Pset_shuffle(plist_id);
        H5Pset_deflate(plist_id, comp_lvl);
    }
    hid_t dset_id = H5Dcreate2(loc_id, name, H5T_NATIVE_DOUBLE, space_id, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    H5Pclose(plist_id);
    H5Sclose(space_id);
    if (dset_id < 0) return false;

    herr_t status = 0;
    if (len > 0 && data != nullptr) {
        status = H5Dwrite(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);
    }
    H5Dclose(dset_id);
    return (status >= 0);
}

// Internal sample representation extracted from Octave struct
struct ParsedSample {
    size_t P = 0;
    size_t T = 0;
    size_t V = 0;
    size_t E = 0;

    std::vector<int32_t> petri_net;       // Row-Major: P x (2T + 1)
    std::vector<int32_t> vertices;        // Row-Major: V x P
    std::vector<int32_t> edges;           // Row-Major: E x 2
    std::vector<int32_t> arc_transitions; // E x 1
    std::vector<double> lambda_values;    // T x 1
    std::vector<double> steady_state_probs; // V x 1
    std::vector<double> avg_markings;     // P x 1
};

static ParsedSample parse_octave_sample(const octave_map& m) {
    ParsedSample s;

    // 1. Petri net matrix
    if (m.contains("petri_net")) {
        octave_value pn_val = m.contents("petri_net")(0);
        int32NDArray pn_mat = pn_val.int32_array_value();
        s.P = pn_mat.rows();
        size_t cols = pn_mat.columns();
        s.T = (cols > 0) ? (cols - 1) / 2 : 0;
        s.petri_net.resize(s.P * cols);
        for (size_t r = 0; r < s.P; r++) {
            for (size_t c = 0; c < cols; c++) {
                s.petri_net[r * cols + c] = pn_mat(r, c);
            }
        }
    }

    // 2. Vertices matrix (V x P)
    if (m.contains("vertices")) {
        octave_value vert_val = m.contents("vertices")(0);
        int32NDArray v_mat = vert_val.int32_array_value();
        s.V = v_mat.rows();
        size_t p_cols = v_mat.columns();
        if (s.P == 0) s.P = p_cols;
        s.vertices.resize(s.V * p_cols);
        for (size_t r = 0; r < s.V; r++) {
            for (size_t c = 0; c < p_cols; c++) {
                s.vertices[r * p_cols + c] = v_mat(r, c);
            }
        }
    }

    // 3. Edges matrix (E x 2)
    if (m.contains("edges")) {
        octave_value edges_val = m.contents("edges")(0);
        int32NDArray e_mat = edges_val.int32_array_value();
        s.E = e_mat.rows();
        s.edges.resize(s.E * 2);
        for (size_t r = 0; r < s.E; r++) {
            s.edges[r * 2 + 0] = e_mat(r, 0);
            s.edges[r * 2 + 1] = e_mat(r, 1);
        }
    }

    // 4. Arc transitions (E x 1)
    if (m.contains("arc_transitions")) {
        octave_value at_val = m.contents("arc_transitions")(0);
        int32NDArray at_mat = at_val.int32_array_value();
        s.arc_transitions.resize(s.E);
        for (size_t i = 0; i < s.E; i++) {
            s.arc_transitions[i] = at_mat(i);
        }
    }

    // 5. Lambda values (T x 1)
    if (m.contains("lambda_values")) {
        octave_value lv_val = m.contents("lambda_values")(0);
        Matrix lv_mat = lv_val.matrix_value();
        size_t len = lv_mat.numel();
        if (s.T == 0) s.T = len;
        s.lambda_values.resize(s.T);
        for (size_t i = 0; i < s.T; i++) {
            s.lambda_values[i] = lv_mat(i);
        }
    }

    // 6. Steady state probs (V x 1)
    if (m.contains("steady_state_probs")) {
        octave_value ssp_val = m.contents("steady_state_probs")(0);
        Matrix ssp_mat = ssp_val.matrix_value();
        size_t len = ssp_mat.numel();
        if (s.V == 0) s.V = len;
        s.steady_state_probs.resize(s.V);
        for (size_t i = 0; i < s.V; i++) {
            s.steady_state_probs[i] = ssp_mat(i);
        }
    }

    // 7. Average markings (P x 1)
    std::string am_field = "";
    if (m.contains("average_markings")) am_field = "average_markings";
    else if (m.contains("avg_markings")) am_field = "avg_markings";

    if (!am_field.empty()) {
        octave_value am_val = m.contents(am_field)(0);
        Matrix am_mat = am_val.matrix_value();
        size_t len = am_mat.numel();
        if (s.P == 0) s.P = len;
        s.avg_markings.resize(s.P);
        for (size_t i = 0; i < s.P; i++) {
            s.avg_markings[i] = am_mat(i);
        }
    }

    return s;
}

DEFUN_DLD(export_dataset_hdf5_oct, args, nargout,
  "-*- texinfo -*-\n\
@deftypefn {} {} export_dataset_hdf5_oct (@var{samples_cell}, @var{filepath}, @var{layout}, @var{compression_level})\n\
High-performance C++ accelerated HDF5 dataset exporter for SPN datasets.\n\
@end deftypefn")
{
    if (args.length() < 2) {
        error("export_dataset_hdf5_oct: Requires at least samples_cell and filepath arguments.");
        return octave_value_list();
    }

    if (!args(0).iscell()) {
        error("export_dataset_hdf5_oct: First argument must be a cell array of sample structs.");
        return octave_value_list();
    }

    Cell samples_cell = args(0).cell_value();
    std::string filepath = args(1).string_value();

    std::string layout = "flat";
    if (args.length() >= 3 && args(2).is_string()) {
        layout = args(2).string_value();
    }

    int comp_lvl = 4;
    if (args.length() >= 4 && args(3).isnumeric()) {
        comp_lvl = args(3).int_value();
        if (comp_lvl < 0) comp_lvl = 0;
        if (comp_lvl > 9) comp_lvl = 9;
    }

    size_t num_samples = samples_cell.numel();
    std::vector<ParsedSample> parsed(num_samples);
    for (size_t i = 0; i < num_samples; i++) {
        parsed[i] = parse_octave_sample(samples_cell(i).map_value());
    }

    // Suppress default HDF5 error printing to stderr
    H5Eset_auto2(H5E_DEFAULT, NULL, NULL);

    hid_t file_id = H5Fcreate(filepath.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    if (file_id < 0) {
        error("export_dataset_hdf5_oct: Failed to create HDF5 file: %s", filepath.c_str());
        return octave_value_list();
    }

    write_attr_string(file_id, "layout", layout);
    write_attr_int32(file_id, "num_samples", (int32_t)num_samples);
    write_attr_int32(file_id, "compression_level", (int32_t)comp_lvl);

    if (layout == "groups") {
        hid_t samples_grp = H5Gcreate2(file_id, "/samples", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
        if (samples_grp < 0) {
            H5Fclose(file_id);
            error("export_dataset_hdf5_oct: Failed to create /samples group.");
            return octave_value_list();
        }

        for (size_t i = 0; i < num_samples; i++) {
            const ParsedSample& s = parsed[i];
            char grp_name[64];
            std::snprintf(grp_name, sizeof(grp_name), "sample_%06zu", i + 1);

            hid_t s_grp = H5Gcreate2(samples_grp, grp_name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
            if (s_grp >= 0) {
                write_attr_int32(s_grp, "num_places", (int32_t)s.P);
                write_attr_int32(s_grp, "num_transitions", (int32_t)s.T);
                write_attr_int32(s_grp, "num_vertices", (int32_t)s.V);
                write_attr_int32(s_grp, "num_edges", (int32_t)s.E);

                write_int32_2d(s_grp, "petri_net", s.petri_net.data(), s.P, 2 * s.T + 1, comp_lvl);
                write_int32_2d(s_grp, "vertices", s.vertices.data(), s.V, (s.V > 0) ? s.vertices.size() / s.V : s.P, comp_lvl);
                write_int32_2d(s_grp, "edges", s.edges.data(), s.E, 2, comp_lvl);
                write_int32_1d(s_grp, "arc_transitions", s.arc_transitions.data(), s.E, comp_lvl);
                write_double_1d(s_grp, "lambda_values", s.lambda_values.data(), s.T, comp_lvl);
                write_double_1d(s_grp, "steady_state_probs", s.steady_state_probs.data(), s.V, comp_lvl);
                write_double_1d(s_grp, "avg_markings", s.avg_markings.data(), s.P, comp_lvl);

                H5Gclose(s_grp);
            }
        }
        H5Gclose(samples_grp);

    } else {
        // Flat layout: CSR-style concatenated arrays with index pointers
        hid_t data_grp = H5Gcreate2(file_id, "/data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
        hid_t ptr_grp = H5Gcreate2(file_id, "/pointers", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

        std::vector<int32_t> marking_ptr(num_samples + 1, 0);
        std::vector<int32_t> edge_ptr(num_samples + 1, 0);
        std::vector<int32_t> pn_ptr(num_samples + 1, 0);
        std::vector<int32_t> num_places(num_samples, 0);
        std::vector<int32_t> num_transitions(num_samples, 0);
        std::vector<int32_t> num_vertices(num_samples, 0);
        std::vector<int32_t> num_edges(num_samples, 0);

        size_t total_v = 0;
        size_t total_e = 0;
        size_t total_pn_elements = 0;
        size_t total_p = 0;
        size_t total_t = 0;
        size_t p0 = (num_samples > 0) ? parsed[0].P : 0;
        bool uniform_p = (num_samples > 0 && p0 > 0);

        for (size_t i = 0; i < num_samples; i++) {
            const ParsedSample& s = parsed[i];
            num_places[i] = (int32_t)s.P;
            num_transitions[i] = (int32_t)s.T;
            num_vertices[i] = (int32_t)s.V;
            num_edges[i] = (int32_t)s.E;

            if (s.P != p0 || (s.V > 0 && s.vertices.size() != s.V * p0)) uniform_p = false;

            marking_ptr[i] = (int32_t)total_v;
            edge_ptr[i] = (int32_t)total_e;
            pn_ptr[i] = (int32_t)total_pn_elements;

            total_v += s.V;
            total_e += s.E;
            total_pn_elements += s.petri_net.size();
            total_p += s.P;
            total_t += s.T;
        }
        marking_ptr[num_samples] = (int32_t)total_v;
        edge_ptr[num_samples] = (int32_t)total_e;
        pn_ptr[num_samples] = (int32_t)total_pn_elements;

        // Write pointers
        write_int32_1d(ptr_grp, "marking_ptr", marking_ptr.data(), num_samples + 1, comp_lvl);
        write_int32_1d(ptr_grp, "edge_ptr", edge_ptr.data(), num_samples + 1, comp_lvl);
        write_int32_1d(ptr_grp, "petri_net_ptr", pn_ptr.data(), num_samples + 1, comp_lvl);
        write_int32_1d(ptr_grp, "num_places", num_places.data(), num_samples, comp_lvl);
        write_int32_1d(ptr_grp, "num_transitions", num_transitions.data(), num_samples, comp_lvl);
        write_int32_1d(ptr_grp, "num_vertices", num_vertices.data(), num_samples, comp_lvl);
        write_int32_1d(ptr_grp, "num_edges", num_edges.data(), num_samples, comp_lvl);

        // Concatenate data arrays
        std::vector<int32_t> all_edges(total_e * 2);
        std::vector<int32_t> all_arc_trans(total_e);
        std::vector<double> all_ssp(total_v);
        std::vector<double> all_lambda(total_t);
        std::vector<double> all_avg_markings(total_p);
        std::vector<int32_t> all_pn(total_pn_elements);

        size_t e_off = 0;
        size_t v_off = 0;
        size_t t_off = 0;
        size_t p_off = 0;
        size_t pn_off = 0;

        for (size_t i = 0; i < num_samples; i++) {
            const ParsedSample& s = parsed[i];

            if (s.E > 0) {
                std::copy(s.edges.begin(), s.edges.end(), all_edges.begin() + e_off * 2);
                std::copy(s.arc_transitions.begin(), s.arc_transitions.end(), all_arc_trans.begin() + e_off);
                e_off += s.E;
            }

            if (s.V > 0) {
                std::copy(s.steady_state_probs.begin(), s.steady_state_probs.end(), all_ssp.begin() + v_off);
                v_off += s.V;
            }

            if (s.T > 0) {
                std::copy(s.lambda_values.begin(), s.lambda_values.end(), all_lambda.begin() + t_off);
                t_off += s.T;
            }

            if (s.P > 0) {
                std::copy(s.avg_markings.begin(), s.avg_markings.end(), all_avg_markings.begin() + p_off);
                p_off += s.P;
            }

            if (!s.petri_net.empty()) {
                std::copy(s.petri_net.begin(), s.petri_net.end(), all_pn.begin() + pn_off);
                pn_off += s.petri_net.size();
            }
        }

        write_int32_2d(data_grp, "edges", all_edges.data(), total_e, 2, comp_lvl);
        write_int32_1d(data_grp, "arc_transitions", all_arc_trans.data(), total_e, comp_lvl);
        write_double_1d(data_grp, "steady_state_probs", all_ssp.data(), total_v, comp_lvl);
        write_double_1d(data_grp, "lambda_values", all_lambda.data(), total_t, comp_lvl);
        write_int32_1d(data_grp, "petri_net", all_pn.data(), total_pn_elements, comp_lvl);

        if (uniform_p && num_samples > 0) {
            write_double_2d(data_grp, "avg_markings", all_avg_markings.data(), num_samples, p0, comp_lvl);

            // Vertices as 2D [total_v x p0]
            std::vector<int32_t> all_vert(total_v * p0);
            size_t curr_v = 0;
            for (size_t i = 0; i < num_samples; i++) {
                const ParsedSample& s = parsed[i];
                if (s.V > 0) {
                    std::copy(s.vertices.begin(), s.vertices.end(), all_vert.begin() + curr_v * p0);
                    curr_v += s.V;
                }
            }
            write_int32_2d(data_grp, "vertices", all_vert.data(), total_v, p0, comp_lvl);
            write_attr_int32(data_grp, "uniform_places", 1);
            write_attr_int32(data_grp, "num_places_per_sample", (int32_t)p0);
        } else {
            write_double_1d(data_grp, "avg_markings", all_avg_markings.data(), total_p, comp_lvl);

            // Mixed places: store linearized marking tokens
            size_t total_tokens = 0;
            for (size_t i = 0; i < num_samples; i++) total_tokens += parsed[i].vertices.size();
            std::vector<int32_t> all_tokens(total_tokens);
            size_t curr_tok = 0;
            for (size_t i = 0; i < num_samples; i++) {
                const ParsedSample& s = parsed[i];
                if (!s.vertices.empty()) {
                    std::copy(s.vertices.begin(), s.vertices.end(), all_tokens.begin() + curr_tok);
                    curr_tok += s.vertices.size();
                }
            }
            write_int32_1d(data_grp, "vertices", all_tokens.data(), total_tokens, comp_lvl);
            write_attr_int32(data_grp, "uniform_places", 0);
        }

        H5Gclose(data_grp);
        H5Gclose(ptr_grp);
    }

    H5Fclose(file_id);
    return octave_value_list();
}
