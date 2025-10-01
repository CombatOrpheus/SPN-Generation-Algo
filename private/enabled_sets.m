%% [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
%%
%% Determines which transitions are enabled in a given marking and computes the
%% resulting successor markings.
%%
%% A transition is considered "enabled" if the current marking `M` has at least
%% as many tokens in each place as are required by the transition's input arcs
%% (defined in the `pre_set` matrix).
%%
%% This function first identifies the set of all such enabled transitions. Then,
%% for each enabled transition, it calculates the new marking that would result
%% from firing that transition.
%%
%% Inputs:
%%   pre_set: The pre-incidence matrix (T_in), where `pre_set(i, j)` is the
%%            weight of the arc from place `i` to transition `j`. This represents
%%            the token requirement for the transition to fire.
%%
%%   post_set: The post-incidence matrix (T_out), where `post_set(i, j)` is the
%%             weight of the arc from transition `j` to place `i`. This represents
%%             the tokens produced by the transition's firing.
%%
%%   M: The current marking of the Petri net, represented as a column vector.
%%
%% Outputs:
%%   new_markings: A matrix where each column is a new marking that can be
%%                 reached from `M` in a single step. The number of columns is
%%                 equal to the number of enabled transitions.
%%
%%   enabled_transitions: A row vector containing the indices of the transitions
%%                        that are enabled in marking `M`.

function [new_markings, enabled_transitions] = enabled_sets(pre_set, post_set, M)
  % Find transitions where the token count in the current marking is sufficient for all input places.
  enabled_transitions = find(all(M >= pre_set, 1));

  % Compute the new markings that result from firing each enabled transition.
  % This is done by subtracting the input tokens and adding the output tokens.
  new_markings = M - pre_set(:, enabled_transitions) + post_set(:, enabled_transitions);
endfunction