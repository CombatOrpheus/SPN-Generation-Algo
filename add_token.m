%% new_net = add_token(petri_matrix, probability)
%%
%% Adds one token to a random subset of places in a Petri net's initial marking.
%%
%% This function provides a way to modify the initial state (M0) of a given
%% Petri net. For each place in the net, a random check is performed against
%% the specified probability. If the check passes, one token is added to that
%% place in the initial marking vector.
%%
%% This is useful for creating variations of a base Petri net or for ensuring
%% that a net has a sufficient number of initial tokens to be live.
%%
%% Inputs:
%%   petri_matrix: The compound matrix representing the SPN. This is a
%%                 pn x (2*tn + 1) matrix where pn is the number of places
%%                 and tn is the number of transitions. The last column of this
%%                 matrix is treated as the initial marking (M0).
%%
%%   probability: (Optional) A scalar value between 0 and 1 representing the
%%                probability that a token will be added to any given place.
%%                If not provided, this defaults to 0.2.
%%
%% Outputs:
%%   new_net: A new compound matrix of the same dimensions as the input,
%%            containing the updated initial marking in its final column.

function new_net = add_token(petri_matrix, probability=0.2)
  num_places = rows(petri_matrix);

  % Create a logical vector to select which places get a new token.
  places_to_increment = rand(num_places, 1) <= probability;

  % Add one token to the last column (the initial marking M0) for the selected places.
  petri_matrix(places_to_increment, end) = petri_matrix(places_to_increment, end) + 1;

  new_net = petri_matrix;
endfunction