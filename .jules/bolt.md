## 2024-05-24 - Octave dot product overhead
**Learning:** In Octave, the built-in `dot()` function can be significantly slower than a direct vector multiplication (`row_vector * column_vector`) for simple vector dot products. This is likely due to function call overhead and internal dimension/type checking in `dot()`.
**Action:** Always prefer direct matrix/vector multiplication (`A * B`) over `dot(A, B)` when calculating dot products of appropriately shaped vectors in performance-critical Octave code.

## 2026-04-08 - Vectorized collision checking
**Learning:** In Octave, loops over items in hash collisions checking for actual matches can be slow.
**Action:** Vectorized comparisons like `matches = all(v_list(:, colliding_indices) == next_marking, 1);` are much faster.

## 2024-04-09 - `containers.Map` Performance in Octave
**Learning:** `containers.Map` has significant overhead in Octave loops due to internal struct/cell manipulation. When profiling the SPN generation/filtering pipeline, `containers.Map` lookups in `get_reachability_graph.m` accounted for over 50% of the execution time.
**Action:** For hash lookups in tight loops, especially when the key space isn't gigantic, use pre-allocated parallel arrays (`hash_list`) and use vectorized `find()` to perform lookups. This provided a 5x-10x speedup in reachability graph exploration compared to `containers.Map`.
