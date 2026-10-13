function player = generate_player(name, type, rates)
  % GENERATE_PLAYER Create a randomly-skilled batter or pitcher.
  %
  %   player = generate_player(name, type)
  %   player = generate_player(name, type, rates)
  %
  %   name  : string, player's name
  %   type  : 'batter' or 'pitcher'
  %   rates : (optional) struct of real per-PA rates as fractions, e.g.
  %           struct('K', 0.2614, 'BB', 0.09, 'HR', 0.04). If omitted,
  %           the player's rates are drawn at random around the league
  %           average.
  %
  % Pipeline for each of K, BB, HR:
  %   1. League average rate        e.g. K = 22.0% of PA
  %   2. League BASELINE            = (league rate)^(1/3) * factor
  %                                   (factor is per event and per type)
  %                                   (the baseline is the d20 pass
  %                                   chance of an average player, so
  %                                   baseline * 20 = league d20 skill)
  %   3. Player real rate           e.g. 26.14%  (drawn, or passed in)
  %   4. Ratio                      = player rate / league rate
  %   5. Player baseline            = league baseline * ratio
  %   6. d20 skill                  = round(20 * player baseline),
  %                                   clamped to 1-20
  %
  % In the deadball roll a K/BB/HR "possibility" stands only if BOTH
  % the batter and the pitcher roll a d20 that is <= their own skill
  % of that name. Higher skill always means "more of that event":
  %   batter K  = strikeout-prone      pitcher K  = strikes batters out
  %   batter BB = draws walks          pitcher BB = issues walks
  %   batter HR = hits homers          pitcher HR = gives up homers

  % ======================================================================
  % LEAGUE AVERAGES (real per-PA rates, as fractions) -- tune at the top
  % ======================================================================
  LG_K  = 0.220;     % 22.0% strikeouts
  LG_BB = 0.08;     %  8.0% walks
  LG_HR = 0.03;     %  3.0% home runs

  % Baseline factors: baseline = (league rate)^(1/3) * factor.
  % One factor per event, separately for batters and pitchers (6 total).
  % Raise a factor and that skill goes up for that type (more of that
  % possibility standing); lower it and it goes down.
  % Defaults put a league-average player at d20 skills of K 13, BB 16,
  % HR 10 (factor = (skill/20) / league_rate^(1/3)).
  BATTER_FACTOR_K   = 1.10;
  BATTER_FACTOR_BB  = 1.50;
  BATTER_FACTOR_HR  = 1.25;

  PITCHER_FACTOR_K  = 1.00;
  PITCHER_FACTOR_BB = 1.50;
  PITCHER_FACTOR_HR = 2.00;

  % Spread (standard deviation) of real rates around the league
  % average, in fractions of PA (0.014 = 1.4 percentage points).
  % Separate for batters and pitchers. Drawn from a normal
  % distribution (no skew modeled for now) and floored at 0.
  BATTER_SD_K   = 0.050;
  BATTER_SD_BB  = 0.025;
  BATTER_SD_HR  = 0.015;

  PITCHER_SD_K  = 0.050;
  PITCHER_SD_BB = 0.025;
  PITCHER_SD_HR = 0.01;

  % Skill bounds (d20: 1 = 5% to succeed, 20 = always succeeds)
  SKILL_MIN = 1;
  SKILL_MAX = 20;

  % Handedness: share of players who are left-handed (rolled on a d100).
  % Switch hitters aren't modeled yet.
  LG_PCT_LEFT_BATTER  = 0.30;
  LG_PCT_LEFT_PITCHER = 0.25;
  % ======================================================================

  if nargin < 3
    rates = [];
  end

  player.name = name;
  player.type = type;

  if strcmpi(type, 'batter')
    factor = [BATTER_FACTOR_K BATTER_FACTOR_BB BATTER_FACTOR_HR];
    sd     = [BATTER_SD_K BATTER_SD_BB BATTER_SD_HR];
    pct_left = LG_PCT_LEFT_BATTER;
  elseif strcmpi(type, 'pitcher')
    factor = [PITCHER_FACTOR_K PITCHER_FACTOR_BB PITCHER_FACTOR_HR];
    sd     = [PITCHER_SD_K PITCHER_SD_BB PITCHER_SD_HR];
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

  stats  = {'K', 'BB', 'HR'};
  lg     = [LG_K LG_BB LG_HR];

  for i = 1:numel(stats)
    s = stats{i};

    % 2. league baseline
    lg_baseline = lg(i)^(1/3) * factor(i);

    % 3. player's real rate (drawn, or supplied)
    if isempty(rates)
      real_rate = max(0, lg(i) + sd(i) * randn());
    else
      real_rate = rates.(s);
    end

    % 4-5. same ratio to league average, applied to the baseline
    ratio = real_rate / lg(i);
    baseline = lg_baseline * ratio;

    % 6. scale to d20 and round
    player.(s) = max(SKILL_MIN, min(SKILL_MAX, round(20 * baseline)));

    % Keep the intermediate numbers for inspection/printing.
    player.rate.(s)     = real_rate;
    player.ratio.(s)    = ratio;
    player.baseline.(s) = baseline;
  end
end
