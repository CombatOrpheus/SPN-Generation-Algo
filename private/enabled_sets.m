%% [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
%%
%% Given a marking M, finds which transitions are enabled and computes the
%% resulting new markings.
%%
%% NOTE: This function is not used by the current version of
%% `get_reachability_graph.m` (as of 2025-08-09), as the logic has been
%% integrated directly into the main loop for clarity. It is kept here for
%% reference.
%%
%% A transition is enabled if the current marking M has enough tokens in all
%% of its input places.
%%
%% Inputs:
%%   pre_set: The pre-incidence matrix (T_in), where pre_set(i, j) is the number
%%            of tokens required from place i for transition j to fire.
%%   post_set: The post-incidence matrix (T_out), where post_set(i, j) is the
%%             number of tokens produced for place i when transition j fires.
%%   M: The current marking, a column vector.
%%
%% Outputs:
%%   new_markings: A matrix where each column is a possible new marking after
%%                 firing one of the enabled transitions.
%%   enabled_transitions: A vector containing the indices of the enabled
%%                        transitions.

function [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
  % Find transitions where the token count in the current marking is sufficient.
  enabled_transitions = find(all(M >= pre_set, 1));
  % Compute the new markings that result from firing each enabled transition.
  new_markings = M - pre_set(:, enabled_transitions) + post_set(:, enabled_transitions);
endfunction
