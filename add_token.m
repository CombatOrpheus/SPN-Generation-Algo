%% new_net = add_token(petri_matrix, probability=0.2)
%%
%% Adds one token to a random subset of places in a Petri net.
%%
%% This function is useful for changing the initial marking of a Petri net.
%% Each place has a given probability of receiving an additional token.
%%
%% Inputs:
%%   petri_matrix: The compound matrix representing the SPN, with the
%%                 initial marking M0 in the last column.
%%   probability: (Optional) The probability (0 to 1) for each place to
%%                receive a token. Default: 0.2.
%%
%% Outputs:
%%   new_net: The modified compound matrix with an updated initial marking.

function new_net = add_token(petri_matrix, probability=0.2)
  num_places = rows(petri_matrix);

  % Create a logical vector to select which places get a new token.
  places_to_increment = rand(num_places, 1) <= probability;

  % Add one token to the last column (the initial marking M0) for the selected places.
  petri_matrix(places_to_increment, end) = petri_matrix(places_to_increment, end) + 1;

  new_net = petri_matrix;
endfunction
