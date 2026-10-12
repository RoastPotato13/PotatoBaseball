function park = generate_park(name, factor)
  % GENERATE_PARK Build a ballpark and its four handedness split tables.
  %
  %   park = generate_park(name)           random park factors
  %   park = generate_park(name, factor)   factors supplied
  %
  %   name   : string, park's name
  %   factor : (optional) struct with fields R and L, each [K BB HR]:
  %            the park's ratio vs league average for RIGHT-handed and
  %            LEFT-handed batters (1 = average). Doesn't depend on the
  %            pitcher's hand. A missing hand is treated as all 1s. If
  %            factor is omitted, both hands are drawn at random.
  %
  % Pipeline for each of K, BB, HR in each split (PITCHER v BATTER):
  %   1. League BASELINE     = (league rate)^(1/3) * factor
  %   2. League platoon ratio  LEAGUE_SPLIT.(split)   (same in all parks)
  %   3. Park factor           for the batter's hand (R or L)
  %   4. Combined split ratio = platoon ratio * park factor
  %   5. Share of the 96 slots = baseline * combined ratio
  %   6. Slots = round(share * 96); BIP gets the rest; PB/WP is 00-03.
  %
  % Stored on the park (named like player.ratio.K):
  %   park.factor.R.K / .BB / .HR   park factor vs right-handed batters
  %   park.factor.L.K / .BB / .HR   park factor vs left-handed batters
  %   park.baseline.K / .BB / .HR   league baseline (park share)
  %   park.split.RvR.K / .BB / .HR  combined ratio per split (park card)
  %   park.pct.RvR   = [K BB HR]    share of the 96 slots
  %   park.counts.RvR = [K BB HR]   slots after rounding
  %   park.RvR (1x100 cell, index roll+1), park.ranges.RvR (string)

  % ======================================================================
  % LEAGUE AVERAGES (keep in sync with generate_player)
  % ======================================================================
  LG_K  = 0.220;
  LG_BB = 0.08;
  LG_HR = 0.03;

  % Neutral park factors: baseline = (league rate)^(1/3) * factor.
  % Defaults give a neutral park K 60 / BB 15 / HR 15 of the 96 slots.
  FACTOR_K  = 1/(1.1*1.1);%PMB Make sure these match Generate Player file so we end up at league avg.
  FACTOR_BB = 1/(1.5*1.5);
  FACTOR_HR = 1/(1*2);

  % ======================================================================
  % LEAGUE PLATOON SPLITS: pitcher-hand v batter-hand, [K BB HR], 1 = avg.
  % Same for every park. Same-handed matchups favor the pitcher, opposite
  % handed favor the hitter. With the default handedness shares (30% LHB,
  % 25% LHP) these average out to about 1.00, so league rates hold.
  % ======================================================================
  LEAGUE_SPLIT.RvR = [1.03  0.97  0.95 ];
  LEAGUE_SPLIT.RvL = [0.955 1.045 1.075];
  LEAGUE_SPLIT.LvR = [0.955 1.045 1.075];
  LEAGUE_SPLIT.LvL = [1.03  0.97  0.95 ];

  % ======================================================================
  % PARK FACTOR SPREAD: std dev of a park's ratio vs league average,
  % drawn separately for right- and left-handed batters. Ratio units:
  % 0.20 means a typical park is within about +/-20% of average. Normal
  % distribution, floored at 0.
  % ======================================================================
  SD_K  = 0.05;
  SD_BB = 0.05;
  SD_HR = 0.15;

  PBWP_SLOTS = 4;
  % ======================================================================

  if nargin < 2
    factor = [];
  end

  n_slots = 100 - PBWP_SLOTS;          % 96
  stats = {'K', 'BB', 'HR'};
  lg    = [LG_K LG_BB LG_HR];
  fac   = [FACTOR_K FACTOR_BB FACTOR_HR];
  sd    = [SD_K SD_BB SD_HR];

  park.name = name;

  % --- park factors for right- and left-handed batters ---
  hands = {'R', 'L'};
  for h = 1:2
    hd = hands{h};
    if isempty(factor)
      vals = max(0, 1 + sd .* randn(1, 3));      % random park
    elseif isfield(factor, hd)
      vals = factor.(hd);                        % supplied
    else
      vals = [1 1 1];
    end
    for i = 1:3
      park.factor.(hd).(stats{i}) = vals(i);
    end
  end

  for i = 1:3
    park.baseline.(stats{i}) = lg(i)^(1/3) * fac(i);
  end

  % --- combine league platoon and park factor into each split ---
  splits = {'RvR','RvL','LvR','LvL'};
  for k = 1:numel(splits)
    sp = splits{k};
    bh = sp(end);                                % batter's hand

    pct = zeros(1, 3);
    for i = 1:3
      s = stats{i};
      ratio = LEAGUE_SPLIT.(sp)(i) * park.factor.(bh).(s);
      park.split.(sp).(s) = ratio;
      pct(i) = park.baseline.(s) * ratio;
    end

    c = round(pct * n_slots);                    % [K BB HR] slots
    if any(c < 0) || sum(c) > n_slots
      error('generate_park: %s %s counts [%d %d %d] must be >= 0 and total <= %d', ...
            name, sp, c(1), c(2), c(3), n_slots);
    end

    park.pct.(sp)    = pct;
    park.counts.(sp) = c;
    [park.(sp), park.ranges.(sp)] = build_table(c, PBWP_SLOTS);
  end
end

function [tbl, ranges] = build_table(c, pbwp_slots)
  % Build the 1x100 lookup table and a printable ranges string.
  n_bip = 100 - pbwp_slots - sum(c);
  labels = {'PBWP','K','BIP','BB','HR'};
  sizes  = [pbwp_slots, c(1), n_bip, c(2), c(3)];

  tbl = cell(1, 100);
  ranges = '';
  pos = 1;
  for i = 1:numel(labels)
    if sizes(i) == 0
      continue;
    end
    lo = pos;
    hi = pos + sizes(i) - 1;
    tbl(lo:hi) = {labels{i}};
    % tbl is indexed 1-100; the dice read 00-99, so print lo-1, hi-1.
    ranges = [ranges sprintf('%s %02d-%02d  ', labels{i}, lo - 1, hi - 1)];
    pos = hi + 1;
  end
  ranges = strtrim(ranges);
end
