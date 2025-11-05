%% key = hash_marking(marking)
%%
%% Computes a numerical hash of a marking vector using a polynomial rolling hash.
%%
%% This function provides a faster alternative to the weighted sum approach, as
%% it avoids the need for generating a list of prime numbers. It computes the
%% hash as:
%%   key = (v(1) * p^0 + v(2) * p^1 + ... + v(n) * p^(n-1)) mod m
%%
%% where `p` and `m` are large prime numbers. This method is computationally
%% efficient and offers a good distribution of hash keys.
%%
%% Inputs:
%%   marking: A column vector representing the marking of the SPN.
%%
%% Outputs:
%%   key: A numerical hash value of the marking.

function key = hash_marking(marking)
  persistent p_base m_mod powers;
  num_elements = numel(marking);

  if isempty(p_base)
    p_base = 31;
    m_mod = 1e9 + 9;
    powers = 1; % Start with p^0 = 1
  endif

  % If the powers array is not long enough, extend it.
  if numel(powers) < num_elements
    current_size = numel(powers);
    % Pre-allocate the required number of new powers.
    new_powers = zeros(1, num_elements - current_size);
    % The last power in the existing array is our starting point for extension.
    last_power = powers(current_size);

    for i = 1:numel(new_powers)
      % Compute the next power and store it.
      last_power = mod(last_power * p_base, m_mod);
      new_powers(i) = last_power;
    endfor
    powers = [powers, new_powers];
  endif

  key = mod(dot(marking, powers(1:num_elements)), m_mod);
endfunction
