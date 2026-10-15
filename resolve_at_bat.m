function [outcome, rolls, ball] = resolve_at_bat(batter, pitcher, park)
  % RESOLVE_AT_BAT Simulate one plate appearance with dice.
  %
  %   [outcome, rolls, ball] = resolve_at_bat(batter, pitcher, park)
  %
  %   outcome : 'K','BB','HR','1B','2B','OUT','PU','ROE'
  %   rolls   : cell array of strings describing each roll
  %   ball    : batted-ball struct from liveball.m (.kind .side .pos ...),
  %             or [] if the PA never reached the Liveball portion
  %
  % One d100 roll (two d10s, read as 00-99) on the park's table for this
  % pitcher-hand v batter-hand split (e.g. RvL = RHP vs LHB):
  %   00-03   PB/WP: the at-bat continues, so just roll again
  %   04-99   K, BIP, BB or HR, laid out per park and split
  %
  % K/BB/HR are "possibilities": batter and pitcher each roll a d20
  % against their own skill of that name. If both rolls are <= skill
  % the result stands; otherwise move on to the Liveball portion, using
  % the batter's card if the two d20s have opposite oddity and the
  % pitcher's card if they match. BIP goes straight to the Liveball
  % portion with a coin flip for the card (see liveball.m).

  rolls = {};
  ball = [];

  split_key = [pitcher.hand 'v' batter.hand];
  tbl = park.(split_key);

  % PB/WP doesn't end the PA: re-roll until the roll is a real result.
  % (Hook base-runner advancement in here once runners exist.)
  while true
    d100 = randi(100) - 1;      % 00-99, like two d10s
    result = tbl{d100 + 1};     % tables are 1-indexed
    rolls{end+1} = sprintf('Deadball d100 (%s, %s): %02d -> %s', ...
                           park.name, split_key, d100, result);
    if ~strcmp(result, 'PBWP')
      break;
    end
    rolls{end+1} = 'PB/WP -> at-bat continues, re-roll';
  end

  switch result
    case 'BIP'
      [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, '');
    case {'K','BB','HR'}
      [outcome, rolls, ball] = possibility(result, batter, pitcher, park, rolls);
    otherwise
      error('resolve_at_bat: unexpected park result ''%s''', result);
  end
end

function [outcome, rolls, ball] = possibility(event, batter, pitcher, park, rolls)
  ball = [];
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
    if mod(b_roll, 2) ~= mod(p_roll, 2)
      owner = 'batter';
      why = 'opposite';
    else
      owner = 'pitcher';
      why = 'same';
    end
    rolls{end+1} = sprintf('d20s %d and %d have %s oddity -> %s card', ...
                           b_roll, p_roll, why, owner);
    [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, owner);
  end
end

function s = ok_str(tf)
  if tf
    s = 'pass';
  else
    s = 'fail';
  end
end
