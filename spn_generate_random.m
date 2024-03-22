% [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
% Generate a random Stochastic Petri Net as a compound matrix. This does make
% any guarantees regarding the boundedness of the SPN.
% Inputs:
%   pn: The number of places in the net
%   tn: The number of transitions in the net
%   prob: The probability of adding a random edge
%   max_lambda: the maximum value of lambda
% Outputs:
%   cm: The compound matrix (inflows (pn, tn); outflows (pn, tn); M_0 (tn, 1))
%   lambda: A vector with the lambda for each transition.
function [cm, lambda] = spn_generate_random(pn, tn, prob, max_lambda)
  cm = zeros(pn, 2*tn + 1, "logical");

  places = [1:pn]';
  transitions = [1:tn]' + pn;

  sub_gra = [];
  remain_node = [places; transitions];

  % Get a random pair of place and transition to start the process
  pi = random_choice(places);
  tj = random_choice(transitions);
  sub_gra = [pi; tj];
  rand_num = rand();
  tj -= pn; % correcting the index
  if rand_num <= 0.5
    cm(pi, tj) = 1;
  else
    cm(pi, tn + tj) = 1;
  endif

  remain_node = remain_node(remain_node != pi & remain_node != tj);
  node_choices = randperm(remain_node);
  for r_node = node_choices
    p_idxs = sub_gra <= pn;
    if r_node <= pn % r_node is a place
      pi = r_node;
      tj = random_choice(sub_gra(!p_idxs));
    else % r_node is a transition
      pi = random_choice(sub_gra(p_idxs));
      tj = r_node;
    endif

    sub_gra = [sub_gra; r_node];
    rand_num = rand();
    tj -= pn; % correcting the index
    if rand_num <= 0.5
      cm(pi, tj) = 1;
    else
      cm(pi, tn + tj) = 1;
    endif
  endfor

  % For each element in the matrix with a value of zero, we have a probabilitiy
  % prob of setting it to one
  one_idxs = rand(size(cm)) >= prob; % Faster to just generate the whole matrix
  cm(cm == 0 & one_idxs) = 1;

  % If there are no elements equal to one on the last column, randomly select an
  % element and set it to one
  if (~any(cm(:, end)))
    len = numel(cm(:, end));
    i = randi(len);
    cm(i, end) = 1;
  endif

  % For each transition, choose a random value [1, max_lambda] as its lambda
  lambda = randi(max_lambda, tn, 1);
endfunction
