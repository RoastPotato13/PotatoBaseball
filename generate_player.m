function player = generate_player(name, type)
  % GENERATE_PLAYER Create a randomly-skilled batter or pitcher.
  %
  %   player = generate_player(name, type)
  %
  %   name : string, player's name
  %   type : 'batter' or 'pitcher'
  %
  % Every player has three skills on the d20 scale (1-20): K, BB, HR.
  % In the deadball roll, a K/BB/HR "possibility" stands only if BOTH
  % the batter and the pitcher roll a d20 that is <= their own skill
  % of that name. So a higher skill always means "more of that event":
  %   batter K  = strikeout-prone      pitcher K  = strikes batters out
  %   batter BB = draws walks          pitcher BB = issues walks
  %   batter HR = hits homers          pitcher HR = gives up homers

  % ======================================================================
  % LEAGUE AVERAGES (d20 skill scale) -- tune these at the top
  % ======================================================================
  % How these were picked: the deadball d8 sends 4/8 of PAs to a K
  % possibility, 1/8 to BB, 1/8 to HR. Event chance per PA is then
  %   P(event) = P(d8 hits it) * (batterSkill/20) * (pitcherSkill/20)
  % Targets: K ~22%, BB ~8.5%, HR ~3%  ->  skills of about 13 / 16 / 10.
  % (The Ballpark/Split roll may add events later, so retune then.)
  LG_BATTER_K    = 13;
  LG_BATTER_BB   = 16;
  LG_BATTER_HR   = 10;

  LG_PITCHER_K   = 13;
  LG_PITCHER_BB  = 16;
  LG_PITCHER_HR  = 10;

  % Spread (standard deviation) of skills around the league average.
  SD_K  = 3;
  SD_BB = 2.5;
  SD_HR = 3;

  % Skill bounds (d20: 1 = 5% to succeed, 20 = always succeeds)
  SKILL_MIN = 1;
  SKILL_MAX = 20;

  % Handedness: share of players who are left-handed (rolled on a d100).
  % Switch hitters aren't modeled yet.
  LG_PCT_LEFT_BATTER  = 0.30;
  LG_PCT_LEFT_PITCHER = 0.25;
  % ======================================================================

  player.name = name;
  player.type = type;

  if strcmpi(type, 'batter')
    avg_k = LG_BATTER_K;  avg_bb = LG_BATTER_BB;  avg_hr = LG_BATTER_HR;
    pct_left = LG_PCT_LEFT_BATTER;
  elseif strcmpi(type, 'pitcher')
    avg_k = LG_PITCHER_K; avg_bb = LG_PITCHER_BB; avg_hr = LG_PITCHER_HR;
    pct_left = LG_PCT_LEFT_PITCHER;
  else
    error('generate_player: type must be ''batter'' or ''pitcher''');
  end

  % hand: 'R' or 'L' (bats for batters, throws for pitchers)
  if randi(100) <= round(100 * pct_left)
    player.hand = 'L';
  else
    player.hand = 'R';
  end

  player.K  = roll_skill(avg_k,  SD_K,  SKILL_MIN, SKILL_MAX);
  player.BB = roll_skill(avg_bb, SD_BB, SKILL_MIN, SKILL_MAX);
  player.HR = roll_skill(avg_hr, SD_HR, SKILL_MIN, SKILL_MAX);
end

function s = roll_skill(mu, sigma, lo, hi)
  % Rounded normal draw (randn is built in, no statistics package),
  % clamped to the d20 range.
  s = round(mu + sigma * randn());
  s = max(lo, min(hi, s));
end
