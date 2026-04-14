## 2024-05-24 - Octave dot product overhead
**Learning:** In Octave, the built-in `dot()` function can be significantly slower than a direct vector multiplication (`row_vector * column_vector`) for simple vector dot products. This is likely due to function call overhead and internal dimension/type checking in `dot()`.
**Action:** Always prefer direct matrix/vector multiplication (`A * B`) over `dot(A, B)` when calculating dot products of appropriately shaped vectors in performance-critical Octave code.

## 2026-04-08 - Vectorized collision checking
**Learning:** In Octave, loops over items in hash collisions checking for actual matches can be slow.
**Action:** Vectorized comparisons like `matches = all(v_list(:, colliding_indices) == next_marking, 1);` are much faster.

## 2024-04-09 - `containers.Map` Performance in Octave
**Learning:** `containers.Map` has significant overhead in Octave loops due to internal struct/cell manipulation. When profiling the SPN generation/filtering pipeline, `containers.Map` lookups in `get_reachability_graph.m` accounted for over 50% of the execution time.
**Action:** For hash lookups in tight loops, especially when the key space isn't gigantic, use pre-allocated parallel arrays (`hash_list`) and use vectorized `find()` to perform lookups. This provided a 5x-10x speedup in reachability graph exploration compared to `containers.Map`.

## 2024-05-24 - Avoiding O(N^2) in iterative array construction
**Learning:** In Octave, iteratively building an array by using logical filtering on a dynamically growing array inside a loop (e.g., `places = subgraph(subgraph <= pn)`) results in O(N^2) complexity and significant slowdowns for large iterations.
**Action:** Always maintain separate, dynamically growing (or pre-allocated) arrays for distinct subsets of data to ensure O(1) additions and avoid redundant O(N) filtering.

## 2024-05-24 - Using `sum` over `all` for matrix checks
**Learning:** Octave's `sum(matrix, dim) == target` can be slightly faster than `all(matrix == target, dim)` in some tight loop scenarios where the matrix is large.
**Action:** Consider `sum(...) == target` as a micro-optimization alternative to `all(...)` when profiling reveals a bottleneck in logical reductions.

## 2024-04-11 - Loop Overhead with Octave RNG functions
**Learning:** Calling `randi` or `rand` repeatedly inside a `for` loop incurs massive function call overhead in Octave, particularly heavily impacting algorithms that iteratively build graphs element-by-element (like the initial connected graph step in `spn_generate_random.m`).
**Action:** When a loop requires random numbers for each iteration, pre-allocate and pre-compute the random values in vectorized arrays before the loop (e.g., `rand_choices = randi(max_val, num_iterations, 1)`). Inside the loop, read from these pre-computed arrays (and use `mod(val, current_max)+1` to handle dynamic ranges if needed) instead of calling the RNG functions.

## 2024-05-25 - Avoid for-loop concatenation
**Learning:** Constructing arrays by concatenating elements inside `for` loops in Octave is remarkably slow compared to creating matrices using fully vectorized equivalents (`ones()`, vector concatenation).
**Action:** Replace `for` loop array concatenation with block matrix creation (e.g., `connections = [t_in, t_out]`) wherever feasible for significant performance improvements.

## 2024-05-25 - randperm over shuffling entire arrays
**Learning:** When selecting a small random sample (`k`) from a large population, shuffling the entire population array `population(randperm(length(population)))` is inefficient.
**Action:** Use `randperm(numel(population), k)` to generate `k` random indices directly, then index into the population.
## 2024-05-25 - Avoid O(N) array shifting for queues
**Learning:** In Octave, dynamic array shifting operations like `list(1) = []` combined with appending like `list = [list, new_item]` creates an O(N) memory shifting operation for every queue dequeue, which can cause significant performance slowdowns in algorithms like BFS that process many elements.
**Action:** Replace `list(1) = []` pattern with pre-allocated arrays and head/tail pointers (`queue_head`, `queue_tail`) to ensure O(1) queue operations, resizing the array conservatively when `queue_tail` exceeds the bounds.
