%% generate_and_filter_spn(i, pn_range, tn_range, solver)
%%
%% Generates and filters a single Stochastic Petri Net (SPN).
%%
%% This function is designed to be called from a parallel execution loop (e.g.,
%% using `pararrayfun`). It encapsulates one iteration of the SPN generation
%% and validation process.
%%
%% Inputs:
%%   i: An index, typically from the parallel loop, not used in the function.
%%
%%   pn_range: A 1x2 vector `[min, max]` for the number of places.
%%
%%   tn_range: A 1x2 vector `[min, max]` for the number of transitions.
%%
%%   solver: A string specifying the solver for steady-state analysis.
%%
%% Outputs:
%%   result: A struct containing the filtered SPN data. If the SPN is valid,
%%           the struct will be the output of `filter_spn`. If it is invalid,
%%           the struct will have a 'valid' field set to false.

function result = generate_and_filter_spn(i, pn_range, tn_range, solver)
  % The input 'i' is unused, but required by pararrayfun.

  % --- 1. Generate Random Parameters ---
  pn = randi(pn_range);
  tn = randi(tn_range);

  % --- 2. Generate and Filter SPN ---
  % Define generation and filtering parameters. These are hardcoded for now,
  % matching the values in `generate_dataset.m`.
  prob = 0.5;
  max_lambda = 10;
  max_initial_tokens = 10;
  max_token_per_place = 4;
  max_states = 500;

  % Generate a random SPN
  [cm, ~] = spn_generate_random(pn, tn, prob, max_lambda);

  % Filter the SPN
  filter_result = filter_spn(cm, max_initial_tokens, max_token_per_place, max_states, solver);

  % --- 3. Prepare result ---
  if filter_result.valid
    % Add pn and tn to the result for binning purposes
    filter_result.pn = pn;
    filter_result.tn = tn;
    result = filter_result;
  else
    % Return a simple struct for invalid SPNs
    result = struct('valid', false);
  endif
endfunction