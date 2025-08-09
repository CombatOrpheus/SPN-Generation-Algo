%% [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
%%
%% Builds the state transition matrix for a Continuous-Time Markov Chain (CTMC).
%%
%% The state transition matrix (also known as the generator matrix) is fundamental
%% for analyzing the steady-state behavior of the SPN.
%%
%% Inputs:
%%   v_list: A list of all reachable markings (states) of the SPN.
%%   edge_list: A list of all transitions between markings.
%%   arctrans_list: The transition that corresponds to each edge.
%%   lambda: The firing rates for each transition in the SPN.
%%
%% Outputs:
%%   state_matrix: The state transition matrix (generator matrix).
%%   y_list: The right-hand side vector for solving the steady-state equation.

function [state_matrix, y_list] = state_equation(v_list, edge_list, arctrans_list, lambda)
  num_markings = columns(v_list);

  % The state matrix Q for a CTMC has the property that rows sum to 0.
  % The equation to solve for steady-state probabilities 'pi' is pi * Q = 0.
  % To get a unique solution, we replace one equation with the constraint
  % that all probabilities must sum to 1.

  % We build a redundant system first, then modify it.
  redundant_state_matrix = zeros(num_markings, num_markings);

  for i = 1:rows(edge_list)
    source_marking_idx = edge_list(i, 1);
    dest_marking_idx = edge_list(i, 2);
    transition_idx = round(arctrans_list(i)); % Using round() to ensure integer index.

    % The rate of leaving the source state.
    redundant_state_matrix(source_marking_idx, source_marking_idx) -= lambda(transition_idx);
    % The rate of entering the destination state from the source state.
    redundant_state_matrix(dest_marking_idx, source_marking_idx) += lambda(transition_idx);
  endfor

  % To solve the system, we replace the last row with the conservation law
  % (sum of probabilities = 1).
  state_matrix = redundant_state_matrix;
  state_matrix(end, :) = 1;

  % The right-hand side vector y, where Q*pi = y. For steady state, y is all
  % zeros, except for the row we replaced.
  y_list = zeros(num_markings, 1);
  y_list(end) = 1;
endfunction
