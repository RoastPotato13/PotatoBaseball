function [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, owner)
  % LIVEBALL Resolve a ball in play.
  %
  %   [outcome, rolls, ball] = liveball(batter, pitcher, park, rolls, owner)
  %
  %   owner   : 'batter' or 'pitcher' (whose card to use), or '' to flip
  %             a coin (used for a straight BIP from the deadball roll).
  %             For a failed K/BB/HR possibility the caller decides from
  %             the two d20s: opposite oddity -> batter, same -> pitcher.
  %   outcome : 'PU','OUT','1B','2B','ROE'
  %   rolls   : incoming cell array with this portion's rolls appended
  %   ball    : struct for later stages: .owner .code .kind .side
  %             .action .pos (the fielder the ball ends up with)
  %             .try_pos (infielder who missed it, if it got through)
  %             .check ('ERROR','RANGE','CLOSEPLAY','FIELD','PARK' or ''),
  %             .check_pos (the fielder who made a fielding-type check),
  %             .check_passed (true = made the play / out)
  %
  % Roll 1, d100 on the chosen card: one of 11 definitive results
  %   (see generate_contact). PU ends here: it's an out that counts like
  %   a K, no fielder.
  % Roll 2, d20 on the branch table for that result (liveball_tables):
  %   picks the fielder and whether a check is needed. A GBC card result
  %   (ground-ball check) always goes to the GB_CHECK table.
  % Roll 3, d20 (only for checks): d20 <= skill -> pass.
  %   ERROR     pass = out, fail = ROE (reached on error, not a hit)
  %   RANGE     pass = out, fail = single that gets through to the OF
  %   CLOSEPLAY pass = out, fail = infield single (ball stays with the
  %             infielder)
  %   FIELD     pass = out, fail = hit stands (outfielder catch)
  %   PARK      pass = out, fail = hit stands; park skills come from
  %             park.fence (see generate_fence), LF and RF only. A corner
  %             outfielder's check uses his own field; a ball to CF uses
  %             the LF or RF value for the side it was hit to.
  % Skills per check type live in liveball_tables (T.skill).
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
  code = card{d100 + 1};                % 'PU', 'GBO_P', 'GBC_O', ...
  rolls{end+1} = sprintf('Liveball d100 (%s card): %02d -> %s', owner, d100, code);

  ball = struct('owner', owner, 'code', code, 'kind', '', 'side', '', ...
                'action', '', 'pos', '', 'try_pos', '', ...
                'check', '', 'check_pos', '', 'check_passed', false);

  if strcmp(code, 'PU')
    ball.kind = 'PU';
    outcome = 'PU';
    rolls{end+1} = 'Pop-up -> PU (no fielder, counts like a K)';
    return;
  end

  kind = code(1:3);                     % GBO FBO GBC FB1 FB2
  side = code(5);                       % P or O
  ball.kind = kind;
  ball.side = side;

  switch kind
    case 'GBO'
      tbl = T.GB_OUT;    hit = '';
    case 'FBO'
      tbl = T.FB_OUT;    hit = '';
    case 'GBC'
      tbl = T.GB_CHECK;  hit = '1B';
    case 'FB1'
      tbl = T.FB_HIT;    hit = '1B';
    case 'FB2'
      tbl = T.FB_HIT;    hit = '2B';
    otherwise
      error('liveball: unexpected card result ''%s''', code);
  end

  % --- roll 2: fielder and check type ---
  d20 = randi(20);
  action = tbl{d20};                    % e.g. 'RANGE_MI_CF'
  parts = strsplit(action, '_');        % verb, role, optional get-through role
  verb = parts{1};
  role = parts{2};
  thru = '';
  if numel(parts) >= 3
    thru = parts{3};
  end
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
    case 'ERROR'
      [passed, rolls] = skill_check(sprintf('Error (%s)', pos), ...
                                    fielder_skill(pos, verb, T), rolls, ...
                                    'pass -> out', 'fail -> error, batter reaches');
      ball.check = verb;
      ball.check_pos = pos;
      ball.check_passed = passed;
      if passed
        outcome = 'OUT';
      else
        outcome = 'ROE';
      end
    case {'RANGE', 'FIELD'}
      [passed, rolls] = skill_check(sprintf('%s (%s)', check_label(verb), pos), ...
                                    fielder_skill(pos, verb, T), rolls);
      ball.check = verb;
      ball.check_pos = pos;
      ball.check_passed = passed;
      if passed
        outcome = 'OUT';
      else
        outcome = hit;
        if ~isempty(thru)
          % Missed infield ball rolls through to the outfield.
          ball.try_pos = pos;
          pos = position_for(thru, side, batter.hand);
          ball.pos = pos;
          rolls{end+1} = sprintf('Gets through -> hit to %s', pos);
        end
      end
    case 'CLOSEPLAY'
      [passed, rolls] = skill_check(sprintf('Close play (%s)', pos), ...
                                    fielder_skill(pos, verb, T), rolls, ...
                                    'pass -> out', 'fail -> infield hit');
      ball.check = verb;
      ball.check_pos = pos;
      ball.check_passed = passed;
      if passed
        outcome = 'OUT';
      else
        outcome = hit;                  % ball stays with the infielder
      end
    case 'PARK'
      field = park_field(pos, side, batter.hand);
      [passed, rolls] = skill_check(sprintf('Ballpark %s/%s %s', pos, field, hit), ...
                                    park_skill(park, field, hit, T), rolls);
      ball.check = 'PARK';
      ball.check_passed = passed;
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

function s = check_label(verb)
  switch verb
    case 'RANGE'
      s = 'Range';
    case 'FIELD'
      s = 'Fielding';
    otherwise
      s = verb;
  end
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

function skill = fielder_skill(pos, verb, T)
  % Hook for real fielders (and batter speed for CLOSEPLAY) later.
  % For now each check type has one league-average skill in liveball_tables.
  skill = T.skill.(verb);
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

function [passed, rolls] = skill_check(label, skill, rolls, pass_txt, fail_txt)
  if nargin < 4
    pass_txt = 'pass -> out';
    fail_txt = 'fail -> hit stands';
  end
  r = randi(20);
  passed = r <= skill;
  if passed
    s = pass_txt;
  else
    s = fail_txt;
  end
  rolls{end+1} = sprintf('%s check: d20 %d vs %d (%s)', label, r, skill, s);
end
