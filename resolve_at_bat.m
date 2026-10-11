function [outcome, rolls] = resolve_at_bat(batter, pitcher, park)
  % RESOLVE_AT_BAT Simulate one plate appearance with dice.
  %
  %   [outcome, rolls] = resolve_at_bat(batter, pitcher, park)
  %
  %   outcome : 'K','BB','HR','1B','2B','3B','PBWP','LIVEBALL'
  %             (PBWP and LIVEBALL are stubs until those stages exist)
  %   rolls     : cell array of strings describing each roll
  %
  % Deadball roll (d8):
  %   1-2  Ballpark/Split roll (d12 on the park's table for this
  %        pitcher-hand v batter-hand split, e.g. RvL = RHP vs LHB;
  %        slot 1 = PB/WP, slots 2-12 = K, BB, HR or BIP)
  %   3-6  K possibility
  %   7    BB possibility
  %   8    HR possibility
  %
  % Possibility: batter and pitcher each roll a d20 against their own
  % skill of that name (K, BB or HR). If both rolls are <= skill the
  % result stands; otherwise move on to the Liveball portion.

  rolls = {};

  d8 = randi(8);
  rolls{end+1} = sprintf('Deadball d8: %d', d8);

  if d8 <= 2
    % ---- Ballpark/Split roll ----
    split_key = [pitcher.hand 'v' batter.hand];
    tbl = park.(split_key);
    d12 = randi(12);
    result = tbl{d12};
    rolls{end+1} = sprintf('Ballpark/Split d12 (%s, %s): %d -> %s', ...
                         park.name, split_key, d12, result);

    switch result
      case 'PBWP'
        % TODO: PB/WP check. Stub for now.
        outcome = 'PBWP';
        rolls{end+1} = 'PB/WP check (not yet implemented)';
      case 'BIP'
        [outcome, rolls] = liveball(rolls);
      case {'K','BB','HR'}
        [outcome, rolls] = possibility(result, batter, pitcher, rolls);
      otherwise
        error('resolve_at_bat: unexpected park result ''%s''', result);
    end
  else
    % ---- Standard deadball outcomes ----
    if d8 <= 6
      event = 'K';
    elseif d8 == 7
      event = 'BB';
    else
      event = 'HR';
    end
    [outcome, rolls] = possibility(event, batter, pitcher, rolls);
  end
end

function [outcome, rolls] = possibility(event, batter, pitcher, rolls)
  % Batter and pitcher each roll a d20 against their skill of this name.
  b_roll = randi(20);
  p_roll = randi(20);
  b_ok = b_roll <= batter.(event);
  p_ok = p_roll <= pitcher.(event);

  rolls{end+1} = sprintf('%s possibility: batter d20 %d vs %d (%s), pitcher d20 %d vs %d (%s)', ...
    event, b_roll, batter.(event), ok_str(b_ok), ...
    p_roll, pitcher.(event), ok_str(p_ok));

  if b_ok && p_ok
    outcome = event;
    rolls{end+1} = sprintf('%s stands', event);
  else
    rolls{end+1} = 'Not both -> Liveball';
    [outcome, rolls] = liveball(rolls);
  end
end

function [outcome, rolls] = liveball(rolls)
  % TODO: Liveball portion. Stub for now.
  outcome = 'LIVEBALL';
  rolls{end+1} = 'Liveball (not yet implemented)';
end

function s = ok_str(tf)
  if tf
    s = 'pass';
  else
    s = 'fail';
  end
end
