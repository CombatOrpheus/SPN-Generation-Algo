%% [steady_state, mark_density, mu_values, lambda] = generate_steady_state_info(reachability_graph, num_transitions)
%%
%% Generates random firing rates (lambda) and calculates steady-state information.
%%
%% This function computes the steady-state probability distribution of the
%% markings in the reachability graph. From this, it derives other metrics like
%% marking density and the average number of tokens.
%%
%% NOTE: This function was originally named `generate_sgn`.
%%
%% Inputs:
%%   reachability_graph: The reachability graph structure from get_reachability_graph.
%%   num_transitions: The total number of transitions in the SPN.
%%
%% Outputs:
%%   steady_state: The steady-state probability vector for all markings.
%%   mark_density: The marking density list.
%%   mu_values: The average number of tokens in each place at steady-state.
%%   lambda: The randomly generated firing rates.

function [steady_state, mark_density, mu_values, lambda] = generate_steady_state_info(reachability_graph, num_transitions)
  % For this analysis, generate random firing rates for each transition.
  lambda = randi(10, num_transitions, 1);

  % Build and solve the state equations for the CTMC.
  [state_matrix, y_list] = state_equation( ...
    reachability_graph.v_list, ...
    reachability_graph.edge_list, ...
    reachability_graph.arctrans_list, ...
    lambda ...
  );

  % Solve for the steady-state vector 'pi' in 'Q * pi = y'.
  try
    % Use the backslash operator (mldivide) for efficient and accurate solving.
    steady_state = state_matrix \ y_list;
  catch
    % If the matrix is singular or ill-conditioned, the solver will fail.
    steady_state = [];
    mark_density = [];
    mu_values = [];
    return;
  end

  % If a steady-state solution was found, calculate derived metrics.
  if ~isempty(steady_state)
    [mark_density, mu_values] = calculate_average_markings(reachability_graph.v_list, steady_state);
  end
endfunction
