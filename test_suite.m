function test_suite()
    disp("--- Running New Test Suite ---");
    test_spn_generate_random();
    test_get_reachability_graph();
    test_filter_spn();
    test_prune_and_add();
    test_prune_petri_bug();
    disp("--- New Test Suite Completed ---");
endfunction

function test_spn_generate_random()
    disp("--- Testing spn_generate_random ---");

    % Test case 1: Basic generation
    [cm, lambda] = spn_generate_random(3, 2, 0.5, 10);
    assert(all(size(cm) == [3, 5]), "Test Case 1 Failed: Incorrect matrix dimensions");
    assert(is_connected(cm), "Test Case 1 Failed: SPN is not connected");

    % Test case 2: 1x1 SPN
    [cm, lambda] = spn_generate_random(1, 1, 0.5, 10);
    assert(all(size(cm) == [1, 3]), "Test Case 2 Failed: Incorrect matrix dimensions for 1x1 SPN");
    assert(is_connected(cm), "Test Case 2 Failed: 1x1 SPN is not connected");

    % Test case 3: prob = 0 (minimum connections)
    [cm, lambda] = spn_generate_random(5, 5, 0, 10);
    assert(is_connected(cm), "Test Case 3 Failed: SPN with prob=0 is not connected");

    % Test case 4: prob = 1 (maximum connections)
    [cm, lambda] = spn_generate_random(2, 2, 1, 10);
    assert(is_connected(cm), "Test Case 4 Failed: SPN with prob=1 is not connected");
    assert(all(all(cm(:, 1:end-1) == 1)), "Test Case 4 Failed: Matrix not fully connected for prob=1");

    % Test case 5: max_lambda
    [cm, lambda] = spn_generate_random(3, 3, 0.5, 5);
    assert(all(lambda <= 5) && all(lambda >= 1), "Test Case 5 Failed: Lambda values are outside the specified range");

    disp("--- spn_generate_random tests PASSED ---");
endfunction

function connected = is_connected(cm)
    % Helper function to check if the SPN is connected.
    % It builds an adjacency matrix from the incidence matrix and checks for a single connected component.
    [pn, tn_plus_1] = size(cm);
    tn = (tn_plus_1 - 1) / 2;
    incidence_matrix = cm(:, 1:tn) + cm(:, tn+1:2*tn);
    adjacency_matrix = [zeros(pn, pn), incidence_matrix; incidence_matrix', zeros(tn, tn)];

    % Simple graph traversal (BFS) to check for connectivity
    num_nodes = pn + tn;
    visited = false(1, num_nodes);
    queue = 1;
    visited(1) = true;
    count = 1;

    while ~isempty(queue)
        u = queue(1);
        queue(1) = [];

        for v = 1:num_nodes
            if adjacency_matrix(u, v) && ~visited(v)
                visited(v) = true;
                queue(end+1) = v;
                count = count + 1;
            end
        end
    end

    connected = (count == num_nodes);
endfunction

function test_get_reachability_graph()
    disp("--- Testing get_reachability_graph ---");

    % Test case 1: Simple bounded SPN
    T_in = [1, 0; 0, 1];
    T_out = [0, 1; 1, 0];
    M0 = [1; 0];
    cm = [T_in, T_out, M0];
    rg = get_reachability_graph(cm);
    assert(rg.bounded, "Test Case 1 Failed: Simple SPN should be bounded");
    assert(all(size(rg.v_list) == [2, 2]), "Test Case 1 Failed: Incorrect number of vertices");
    assert(all(size(rg.edge_list) == [2, 2]), "Test Case 1 Failed: Incorrect number of edges");

    % Test case 2: Unbounded SPN (place upper limit)
    T_in = [1];
    T_out = [2];
    M0 = [1];
    cm = [T_in, T_out, M0];
    rg = get_reachability_graph(cm, 5);
    assert(!rg.bounded, "Test Case 2 Failed: SPN should be unbounded by place limit");

    % Test case 3: Unbounded SPN (marks upper limit)
    pn = 2; tn = 2;
    T_in = [1 0; 0 1];
    T_out = [0 1; 1 0];
    M0 = [5; 0];
    cm = [T_in, T_out, M0];
    % This SPN is theoretically bounded with 6 reachable markings.
    % This test verifies that the function correctly flags the SPN as "unbounded"
    % when the number of markings exceeds the `marks_upper_limit`.
    rg = get_reachability_graph(cm, 10, 5);
    assert(!rg.bounded, "Test Case 3 Failed: SPN should be unbounded by marks limit");

    % Test case 4: Hash collision
    % All markings in this SPN sum to 5, causing hash collisions.
    % Markings: [1;4], [2;3], [3;2], [4;1], [5;0]
    T_in = [0;1];
    T_out = [1;0];
    M0 = [1;4];
    cm = [T_in, T_out, M0];
    rg = get_reachability_graph(cm);
    assert(rg.bounded, "Test Case 4 Failed: SPN with hash collisions should be bounded");
    assert(columns(rg.v_list) == 5, "Test Case 4 Failed: Incorrect number of vertices with hash collisions");

    disp("--- get_reachability_graph tests PASSED ---");
endfunction

function test_filter_spn()
    disp("--- Testing filter_spn ---");

    % Test case 1: Valid SPN
    T_in = [1, 0; 0, 1];
    T_out = [0, 1; 1, 0];
    M0 = [1; 0];
    cm = [T_in, T_out, M0];
    result = filter_spn(cm);
    assert(result.valid, "Test Case 1 Failed: A valid SPN was marked as invalid");

    % Test case 2: Disconnected SPN
    T_in = [1, 0; 0, 0];
    T_out = [0, 1; 0, 0];
    M0 = [1; 0];
    cm = [T_in, T_out, M0];
    result = filter_spn(cm);
    assert(!result.valid, "Test Case 2 Failed: A disconnected SPN was marked as valid");

    % Test case 3: Unbounded SPN
    T_in = [1];
    T_out = [2];
    M0 = [1];
    cm = [T_in, T_out, M0];
    result = filter_spn(cm);
    assert(!result.valid, "Test Case 3 Failed: An unbounded SPN was marked as valid");

    disp("--- filter_spn tests PASSED ---");
endfunction

function test_prune_and_add()
    disp("--- Testing prune_petri and add_token ---");
    pn = 5;
    tn = 4;
    prob = 0.3;
    max_lambda = 10;
    [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda);

    % Test prune_petri
    pruned_cm = prune_petri(cm);
    assert(all(size(pruned_cm) == size(cm)), "prune_petri returned incorrect dimensions");

    % Test add_token
    cm_with_tokens_default = add_token(cm);
    assert(all(size(cm_with_tokens_default) == size(cm)), "add_token (default) returned incorrect dimensions");
    assert(sum(cm_with_tokens_default(:, end)) >= sum(cm(:, end)), "add_token (default) failed to add tokens");

    cm_with_tokens_custom = add_token(cm, 0.5);
    assert(all(size(cm_with_tokens_custom) == size(cm)), "add_token (custom) returned incorrect dimensions");
    assert(sum(cm_with_tokens_custom(:, end)) >= sum(cm(:, end)), "add_token (custom) failed to add tokens");

    original_tokens = sum(cm(:, end));
    cm_with_all_tokens = add_token(cm, 1.0);
    expected_tokens = original_tokens + pn;
    assert(sum(cm_with_all_tokens(:, end)) == expected_tokens, "add_token (prob=1) failed to add a token to every place");

    disp("--- prune_petri and add_token tests PASSED ---");
endfunction

function test_prune_petri_bug()
    disp("--- Testing prune_petri bug fix ---");
    % This test case constructs a Petri net that is likely to trigger the
    % dimension mismatch bug in the original del_edge.m implementation.
    % The bug occurs when `find` returns a row vector for a single over-connected
    % transition, leading to incorrect iteration.

    T_in = [1; 1; 1];
    T_out = [0; 0; 0];
    M0 = [0; 0; 0];
    cm = [T_in, T_out, M0]; % 3 places, 1 transition

    % The transition is over-connected (degree 3). prune_petri should
    % reduce its connections to 2.
    pruned_cm = prune_petri(cm);

    % The pruning should reduce the connections from 3 to 2. However, this
    % isolates one of the places, which `add_edges_to_isolated_nodes` then
    % reconnects, adding 2 more edges. The final expected count is 4.
    expected_connections = 4;
    actual_connections = sum(sum(pruned_cm(:, 1:end-1)));

    assert(actual_connections == expected_connections, "prune_petri bug test failed: incorrect number of connections after pruning.");
    disp("--- prune_petri bug fix test PASSED ---");
endfunction