%% [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
%% Generate a random Stochastic Petri Net as a compound matrix. This does make
%% any guarantees regarding the boundedness of the SPN.
%% Inputs:
%%   pn: The number of places in the net
%%   tn: The number of transitions in the net
%%   prob: The probability of adding a random connection
%%   max_lambda: the maximum value of lambda (1:lambda)
%% Outputs:
%%   cm: The compound matrix (inflows (pn x tn); outflows (pn x tn); M_0 (tn x 1))
%%   lambda: A vector with the lambda for each transition.
function [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
  cm = zeros(pn, 2*tn + 1, "int32");
  places = [1:pn]';
  transitions = [1:tn]' + pn;
  % Start with an empty graph
  sub_gra = [];
  remaining_nodes = [places; transitions];
  % Get a random (place, transition) pair to start the process.
  pi = randi(pn);
  tj = randi(tn) + pn;
  sub_gra = [pi; tj];
  tj -= pn; % correcting the index

  if rand() <= 0.5
    cm(pi, tj) = 1;      % Connect place to transition
  else
    cm(pi, tn + tj) = 1; % Connect transition to place
  endif

  remaining_nodes = remaining_nodes(remaining_nodes != pi & remaining_nodes != tj);
  node_choices = randperm(remaining_nodes);

  for node = node_choices
    p_idxs = sub_gra <= pn;
    if node <= pn % node is a place
      pi = node; tj = random_choice(sub_gra(~p_idxs));
    else % node is a transition
      pi = random_choice(sub_gra(p_idxs)); tj = node;
    endif

    sub_gra = [sub_gra; node];
    tj -= pn; % correcting the index

    if rand() <= 0.5
      cm(pi, tj) = 1;
    else
      cm(pi, tn + tj) = 1;
    endif
  endfor

  % For each unconnected pair, we have a probabilitiy prob of connecting them.
  one_idxs = rand(size(cm)) <= prob;
  cm(cm == 0 & one_idxs) = 1;
  % If the initial marking is all zeros, create a random marking.
  if (all(cm(:, end) == 0))
    choices = randi(2, pn, 1) - 1;
    cm(:, end) = choices;
  endif
  % For each transition, choose a random value [1, max_lambda] as its lambda.
  lambda = randi(max_lambda, tn, 1);
endfunction
