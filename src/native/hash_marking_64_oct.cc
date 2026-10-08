#include <octave/oct.h>
#include <cstdint>

DEFUN_DLD(hash_marking_64_oct, args, nargout,
          "Compute 64-bit avalanche hash of marking.\n"
          "Syntax: h = hash_marking_64_oct(marking)") {
    if (args.length() < 1) {
        print_usage();
        return octave_value_list();
    }

    const int32NDArray m = args(0).int32_array_value();
    uint64_t h = 0x517cc1b727220a95ULL;
    for (octave_idx_type i = 0; i < m.numel(); i++) {
        h = (h ^ static_cast<uint64_t>(m(i))) * 0xbf58476d1ce4e5b9ULL;
        h = (h ^ (h >> 30)) * 0x94d049bb133111ebULL;
    }
    h = h ^ (h >> 31);

    char buf[32];
    snprintf(buf, sizeof(buf), "%llu", static_cast<unsigned long long>(h));
    return octave_value_list(octave_value(buf));
}
