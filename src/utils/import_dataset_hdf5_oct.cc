// import_dataset_hdf5_oct.cc - High-performance C++ HDF5 dataset loader for SPN datasets
// Supports reading back both 'flat' (CSR-style pointer indexing) and 'groups' (hierarchical) layouts.

#include <octave/oct.h>
#include <octave/Cell.h>
#include <octave/oct-map.h>
#include <hdf5/serial/hdf5.h>

#include <vector>
#include <string>
#include <algorithm>
#include <cstdio>
#include <iostream>

// Helper to read an int32 attribute
static int32_t read_attr_int32(hid_t loc_id, const char* name, int32_t default_val = 0) {
    if (!H5Aexists(loc_id, name)) return default_val;
    hid_t attr_id = H5Aopen(loc_id, name, H5P_DEFAULT);
    if (attr_id < 0) return default_val;
    int32_t val = default_val;
    H5Aread(attr_id, H5T_NATIVE_INT32, &val);
    H5Aclose(attr_id);
    return val;
}

// Helper to read a string attribute
static std::string read_attr_string(hid_t loc_id, const char* name) {
    if (!H5Aexists(loc_id, name)) return "";
    hid_t attr_id = H5Aopen(loc_id, name, H5P_DEFAULT);
    if (attr_id < 0) return "";
    hid_t type_id = H5Aget_type(attr_id);
    size_t size = H5Tget_size(type_id);
    std::vector<char> buf(size + 1, 0);
    H5Aread(attr_id, type_id, buf.data());
    H5Tclose(type_id);
    H5Aclose(attr_id);
    return std::string(buf.data());
}

// Helper: Read 1D int32 dataset
static std::vector<int32_t> read_int32_1d(hid_t loc_id, const char* name) {
    if (!H5Lexists(loc_id, name, H5P_DEFAULT)) return {};
    hid_t dset_id = H5Dopen2(loc_id, name, H5P_DEFAULT);
    if (dset_id < 0) return {};
    hid_t space_id = H5Dget_space(dset_id);
    hsize_t dims[1];
    H5Sget_simple_extent_dims(space_id, dims, NULL);
    std::vector<int32_t> data(dims[0]);
    if (dims[0] > 0) {
        H5Dread(dset_id, H5T_NATIVE_INT32, H5S_ALL, H5S_ALL, H5P_DEFAULT, data.data());
    }
    H5Sclose(space_id);
    H5Dclose(dset_id);
    return data;
}

// Helper: Read 1D double dataset
static std::vector<double> read_double_1d(hid_t loc_id, const char* name) {
    if (!H5Lexists(loc_id, name, H5P_DEFAULT)) return {};
    hid_t dset_id = H5Dopen2(loc_id, name, H5P_DEFAULT);
    if (dset_id < 0) return {};
    hid_t space_id = H5Dget_space(dset_id);
    hsize_t dims[1];
    H5Sget_simple_extent_dims(space_id, dims, NULL);
    std::vector<double> data(dims[0]);
    if (dims[0] > 0) {
        H5Dread(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data.data());
    }
    H5Sclose(space_id);
    H5Dclose(dset_id);
    return data;
}

// Helper: Read 2D int32 dataset (stored Row-Major in HDF5, converted to Octave int32NDArray)
static int32NDArray read_int32_2d(hid_t loc_id, const char* name) {
    if (!H5Lexists(loc_id, name, H5P_DEFAULT)) return int32NDArray();
    hid_t dset_id = H5Dopen2(loc_id, name, H5P_DEFAULT);
    if (dset_id < 0) return int32NDArray();
    hid_t space_id = H5Dget_space(dset_id);
    hsize_t dims[2];
    H5Sget_simple_extent_dims(space_id, dims, NULL);
    size_t R = dims[0];
    size_t C = dims[1];
    std::vector<int32_t> buf(R * C);
    if (R > 0 && C > 0) {
        H5Dread(dset_id, H5T_NATIVE_INT32, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf.data());
    }
    H5Sclose(space_id);
    H5Dclose(dset_id);

    int32NDArray mat(dim_vector(R, C));
    for (size_t r = 0; r < R; r++) {
        for (size_t c = 0; c < C; c++) {
            mat(r, c) = buf[r * C + c];
        }
    }
    return mat;
}

// Helper: Read 2D double dataset (stored Row-Major in HDF5, converted to Octave Matrix)
static Matrix read_double_2d(hid_t loc_id, const char* name) {
    if (!H5Lexists(loc_id, name, H5P_DEFAULT)) return Matrix();
    hid_t dset_id = H5Dopen2(loc_id, name, H5P_DEFAULT);
    if (dset_id < 0) return Matrix();
    hid_t space_id = H5Dget_space(dset_id);
    hsize_t dims[2];
    H5Sget_simple_extent_dims(space_id, dims, NULL);
    size_t R = dims[0];
    size_t C = dims[1];
    std::vector<double> buf(R * C);
    if (R > 0 && C > 0) {
        H5Dread(dset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf.data());
    }
    H5Sclose(space_id);
    H5Dclose(dset_id);

    Matrix mat(R, C);
    for (size_t r = 0; r < R; r++) {
        for (size_t c = 0; c < C; c++) {
            mat(r, c) = buf[r * C + c];
        }
    }
    return mat;
}

DEFUN_DLD(import_dataset_hdf5_oct, args, nargout,
  "-*- texinfo -*-\n\
@deftypefn {} {@var{samples} =} import_dataset_hdf5_oct (@var{filepath})\n\
High-performance C++ accelerated HDF5 dataset loader for SPN datasets.\n\
@end deftypefn")
{
    if (args.length() < 1 || !args(0).is_string()) {
        error("import_dataset_hdf5_oct: First argument must be a filepath string.");
        return octave_value_list();
    }

    std::string filepath = args(0).string_value();

    // Suppress default HDF5 error printing to stderr
    H5Eset_auto2(H5E_DEFAULT, NULL, NULL);

    hid_t file_id = H5Fopen(filepath.c_str(), H5F_ACC_RDONLY, H5P_DEFAULT);
    if (file_id < 0) {
        error("import_dataset_hdf5_oct: Failed to open HDF5 file: %s", filepath.c_str());
        return octave_value_list();
    }

    std::string layout = read_attr_string(file_id, "layout");
    int32_t num_samples_attr = read_attr_int32(file_id, "num_samples", 0);

    if (layout.empty()) {
        if (H5Lexists(file_id, "/samples", H5P_DEFAULT)) {
            layout = "groups";
        } else if (H5Lexists(file_id, "/data", H5P_DEFAULT)) {
            layout = "flat";
        } else {
            H5Fclose(file_id);
            error("import_dataset_hdf5_oct: Unrecognized HDF5 dataset schema in %s", filepath.c_str());
            return octave_value_list();
        }
    }

    Cell result_cells;

    if (layout == "groups") {
        hid_t samples_grp = H5Gopen2(file_id, "/samples", H5P_DEFAULT);
        if (samples_grp < 0) {
            H5Fclose(file_id);
            error("import_dataset_hdf5_oct: /samples group missing.");
            return octave_value_list();
        }

        hsize_t num_obj = 0;
        H5Gget_num_objs(samples_grp, &num_obj);
        size_t N = (num_samples_attr > 0) ? (size_t)num_samples_attr : (size_t)num_obj;
        result_cells = Cell(N, 1);

        for (size_t i = 0; i < N; i++) {
            char grp_name[64];
            std::snprintf(grp_name, sizeof(grp_name), "sample_%06zu", i + 1);

            if (H5Lexists(samples_grp, grp_name, H5P_DEFAULT)) {
                hid_t s_grp = H5Gopen2(samples_grp, grp_name, H5P_DEFAULT);
                if (s_grp >= 0) {
                    octave_scalar_map m;
                    m.setfield("petri_net", read_int32_2d(s_grp, "petri_net"));
                    m.setfield("vertices", read_int32_2d(s_grp, "vertices"));
                    m.setfield("edges", read_int32_2d(s_grp, "edges"));

                    std::vector<int32_t> at = read_int32_1d(s_grp, "arc_transitions");
                    int32NDArray at_mat(dim_vector(at.size(), 1));
                    for (size_t k = 0; k < at.size(); k++) at_mat(k) = at[k];
                    m.setfield("arc_transitions", at_mat);

                    std::vector<double> lv = read_double_1d(s_grp, "lambda_values");
                    ColumnVector lv_vec(lv.size());
                    for (size_t k = 0; k < lv.size(); k++) lv_vec(k) = lv[k];
                    m.setfield("lambda_values", lv_vec);

                    std::vector<double> ssp = read_double_1d(s_grp, "steady_state_probs");
                    ColumnVector ssp_vec(ssp.size());
                    for (size_t k = 0; k < ssp.size(); k++) ssp_vec(k) = ssp[k];
                    m.setfield("steady_state_probs", ssp_vec);

                    std::vector<double> am = read_double_1d(s_grp, "avg_markings");
                    ColumnVector am_vec(am.size());
                    for (size_t k = 0; k < am.size(); k++) am_vec(k) = am[k];
                    m.setfield("avg_markings", am_vec);

                    result_cells(i) = m;
                    H5Gclose(s_grp);
                }
            }
        }
        H5Gclose(samples_grp);

    } else {
        // Flat layout
        hid_t data_grp = H5Gopen2(file_id, "/data", H5P_DEFAULT);
        hid_t ptr_grp = H5Gopen2(file_id, "/pointers", H5P_DEFAULT);
        if (data_grp < 0 || ptr_grp < 0) {
            if (data_grp >= 0) H5Gclose(data_grp);
            if (ptr_grp >= 0) H5Gclose(ptr_grp);
            H5Fclose(file_id);
            error("import_dataset_hdf5_oct: /data or /pointers group missing in flat layout.");
            return octave_value_list();
        }

        std::vector<int32_t> marking_ptr = read_int32_1d(ptr_grp, "marking_ptr");
        std::vector<int32_t> edge_ptr = read_int32_1d(ptr_grp, "edge_ptr");
        std::vector<int32_t> pn_ptr = read_int32_1d(ptr_grp, "petri_net_ptr");
        std::vector<int32_t> num_places = read_int32_1d(ptr_grp, "num_places");
        std::vector<int32_t> num_transitions = read_int32_1d(ptr_grp, "num_transitions");
        std::vector<int32_t> num_vertices = read_int32_1d(ptr_grp, "num_vertices");
        std::vector<int32_t> num_edges = read_int32_1d(ptr_grp, "num_edges");

        size_t N = num_places.size();
        result_cells = Cell(N, 1);

        int32NDArray all_edges = read_int32_2d(data_grp, "edges");
        std::vector<int32_t> all_at = read_int32_1d(data_grp, "arc_transitions");
        std::vector<double> all_ssp = read_double_1d(data_grp, "steady_state_probs");
        std::vector<double> all_lv = read_double_1d(data_grp, "lambda_values");
        std::vector<int32_t> all_pn = read_int32_1d(data_grp, "petri_net");

        int32_t uniform_p = read_attr_int32(data_grp, "uniform_places", 1);
        int32NDArray all_vert_2d;
        std::vector<int32_t> all_vert_1d;
        Matrix all_am_2d;
        std::vector<double> all_am_1d;

        if (uniform_p) {
            all_vert_2d = read_int32_2d(data_grp, "vertices");
            all_am_2d = read_double_2d(data_grp, "avg_markings");
        } else {
            all_vert_1d = read_int32_1d(data_grp, "vertices");
            all_am_1d = read_double_1d(data_grp, "avg_markings");
        }

        size_t curr_vert_tok = 0;
        size_t curr_am_idx = 0;
        size_t curr_lv_idx = 0;

        for (size_t i = 0; i < N; i++) {
            size_t P = num_places[i];
            size_t T = num_transitions[i];
            size_t V = num_vertices[i];
            size_t E = num_edges[i];

            octave_scalar_map m;

            // Petri net matrix
            size_t pn_start = pn_ptr[i];
            size_t pn_cols = 2 * T + 1;
            int32NDArray pn_mat(dim_vector(P, pn_cols));
            for (size_t r = 0; r < P; r++) {
                for (size_t c = 0; c < pn_cols; c++) {
                    pn_mat(r, c) = all_pn[pn_start + r * pn_cols + c];
                }
            }
            m.setfield("petri_net", pn_mat);

            // Vertices matrix
            int32NDArray v_mat(dim_vector(V, P));
            if (uniform_p) {
                size_t v_start = marking_ptr[i];
                for (size_t r = 0; r < V; r++) {
                    for (size_t c = 0; c < P; c++) {
                        v_mat(r, c) = all_vert_2d(v_start + r, c);
                    }
                }
            } else {
                for (size_t r = 0; r < V; r++) {
                    for (size_t c = 0; c < P; c++) {
                        v_mat(r, c) = all_vert_1d[curr_vert_tok++];
                    }
                }
            }
            m.setfield("vertices", v_mat);

            // Edges matrix
            size_t e_start = edge_ptr[i];
            int32NDArray e_mat(dim_vector(E, 2));
            int32NDArray at_mat(dim_vector(E, 1));
            for (size_t r = 0; r < E; r++) {
                e_mat(r, 0) = all_edges(e_start + r, 0);
                e_mat(r, 1) = all_edges(e_start + r, 1);
                at_mat(r) = all_at[e_start + r];
            }
            m.setfield("edges", e_mat);
            m.setfield("arc_transitions", at_mat);

            // Steady state probs
            size_t v_start = marking_ptr[i];
            ColumnVector ssp_vec(V);
            for (size_t r = 0; r < V; r++) {
                ssp_vec(r) = all_ssp[v_start + r];
            }
            m.setfield("steady_state_probs", ssp_vec);

            // Lambda values
            ColumnVector lv_vec(T);
            for (size_t r = 0; r < T; r++) {
                lv_vec(r) = all_lv[curr_lv_idx++];
            }
            m.setfield("lambda_values", lv_vec);

            // Average markings
            ColumnVector am_vec(P);
            if (uniform_p) {
                for (size_t r = 0; r < P; r++) {
                    am_vec(r) = all_am_2d(i, r);
                }
            } else {
                for (size_t r = 0; r < P; r++) {
                    am_vec(r) = all_am_1d[curr_am_idx++];
                }
            }
            m.setfield("avg_markings", am_vec);

            result_cells(i) = m;
        }

        H5Gclose(data_grp);
        H5Gclose(ptr_grp);
    }

    H5Fclose(file_id);
    return octave_value(result_cells);
}
