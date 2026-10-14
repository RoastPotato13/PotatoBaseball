function [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, owner)
  % LIVEBALL Resolve a ball in play.
  %
  %   [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, owner)
  %
  %   owner   : 'batter' or 'pitcher' (whose card to use), or '' to flip
  %             a coin (used for a straight BIP from the deadball roll).
  %             For a failed K/BB/HR possibility the caller decides from
  %             the two d20s: opposite oddity -> batter, same -> pitcher.
  %   outcome : 'PU','OUT','1B','2B'
  %   rolls   : incoming cell array with this portion's rolls appended
  %   ball    : struct for later stages: .owner .code .kind .side
  %             .action .pos (the fielder / field involved)
  %
  % Roll 1, d100 on the chosen card: one of 11 definitive results
  %   (see generate_contact). PU ends here: it's an out that counts like
  %   a K, no fielder.
  % Roll 2, d20 on the branch table for that result (liveball_tables):
  %   picks the fielder and whether a check is needed.
  % Roll 3, d20 (only for checks): FIELD_xx is a fielding check and
  %   PARK_xx is a ballpark check. d20 <= skill -> OUT, otherwise the
  %   hit stands. All fielders are skill 10 for now; park skills come
  %   from park.fence (see generate_fence), which has LF and RF only.
  %   A corner outfielder's ballpark check uses his own field; a ball
  %   to CF uses the LF or RF value for the side it was hit to.
  %
  % No triples. HR is decided in the deadball roll only.

  if nargin < 5
    owner = '';
  end
  T = liveball_tables();

  % --- which card ---
  if isempty(owner)
    if randi(2) == 1
      owner = 'batter';
    else
      owner = 'pitcher';
    end
    rolls{end+1} = sprintf('Card coin flip -> %s card', owner);
  end
  if strcmp(owner, 'batter')
    card = batter.contact.card;
  else
    card = pitcher.contact.card;
  end

  % --- roll 1: the card ---
  d100 = randi(100) - 1;                % 00-99
  code = card{d100 + 1};                % 'PU', 'GBO_P', 'FB2_O', ...
  rolls{end+1} = sprintf('Liveball d100 (%s card): %02d -> %s', owner, d100, code);

  ball = struct('owner', owner, 'code', code, 'kind', '', 'side', '', ...
                'action', '', 'pos', '');

  if strcmp(code, 'PU')
    ball.kind = 'PU';
    outcome = 'PU';
    rolls{end+1} = 'Pop-up -> PU (no fielder, counts like a K)';
    return;
  end

  kind = code(1:3);                     % GBO FBO GB1 FB1 FB2
  side = code(5);                       % P or O
  ball.kind = kind;
  ball.side = side;

  switch kind
    case 'GBO'
      tbl = T.GB_OUT;  hit = '';
    case 'FBO'
      tbl = T.FB_OUT;  hit = '';
    case 'GB1'
      tbl = T.GB_HIT;  hit = '1B';
    case 'FB1'
      tbl = T.FB_HIT;  hit = '1B';
    case 'FB2'
      tbl = T.FB_HIT;  hit = '2B';
    otherwise
      error('liveball: unexpected card result ''%s''', code);
  end

  % --- roll 2: fielder and check type ---
  d20 = randi(20);
  action = tbl{d20};                    % e.g. 'FIELD_MI'
  us = find(action == '_', 1);
  verb = action(1:us - 1);
  role = action(us + 1:end);
  pos  = position_for(role, side, batter.hand);
  ball.action = action;
  ball.pos = pos;
  rolls{end+1} = sprintf('Branch d20: %d -> %s (%s)', d20, action, pos);

  % --- roll 3: checks ---
  switch verb
    case 'OUT'
      outcome = 'OUT';
      % TODO: slow grounder (GB outs), probably with a 4th d20.
    case 'HIT'
      outcome = hit;
    case 'FIELD'
      [passed, rolls] = skill_check(sprintf('Fielding (%s)', pos), ...
                                    fielder_skill(pos, T), rolls);
      if passed
        outcome = 'OUT';
      else
        outcome = hit;
      end
    case 'PARK'
      field = park_field(pos, side, batter.hand);
      [passed, rolls] = skill_check(sprintf('Ballpark %s/%s %s', pos, field, hit), ...
                                    park_skill(park, field, hit, T), rolls);
      if passed
        outcome = 'OUT';
      else
        outcome = hit;
      end
    otherwise
      error('liveball: unexpected action ''%s''', action);
  end
  rolls{end+1} = sprintf('-> %s', outcome);
end

function tf = is_left_side(side, hand)
  % RHB pull and LHB opp go to the left side of the field (3B/SS/LF).
  tf = (hand == 'R') == (side == 'P');
end

function field = park_field(pos, side, hand)
  % Which park field's skill applies. A ball to CF still counts as hit
  % to the left or right side, so it uses the LF or RF value.
  if strcmp(pos, 'CF')
    if is_left_side(side, hand)
      field = 'LF';
    else
      field = 'RF';
    end
  else
    field = pos;
  end
end

function pos = position_for(role, side, hand)
  % Turn a role + Pull/Opp + batter hand into a position.
  left_side = is_left_side(side, hand);
  switch role
    case 'MI'
      if left_side, pos = 'SS'; else pos = '2B'; end
    case 'CI'
      if left_side, pos = '3B'; else pos = '1B'; end
    case 'CO'
      if left_side, pos = 'LF'; else pos = 'RF'; end
    case 'CF'
      pos = 'CF';
    otherwise
      error('liveball: unknown role ''%s''', role);
  end
end

function skill = fielder_skill(pos, T)
  % Hook for real fielders later. Everyone is league average for now.
  skill = T.default_skill;
end

function skill = park_skill(park, field, hit, T)
  % Ballpark skill ('LF' or 'RF') for a hit type ('1B' or '2B').
  % Falls back to league average if the park has no fence skills yet.
  if isfield(park, 'fence')
    skill = park.fence.(field).(['B' hit(1)]);
  else
    skill = T.default_skill;
  end
end

function [passed, rolls] = skill_check(label, skill, rolls)
  r = randi(20);
  passed = r <= skill;
  if passed
    s = 'pass -> out';
  else
    s = 'fail -> hit stands';
  end
  rolls{end+1} = sprintf('%s check: d20 %d vs %d (%s)', label, r, skill, s);
end
