function park = get_park(name)
  % GET_PARK Return a ballpark and its four handedness split tables.
  %
  %   park = get_park(name)    name: 'spudsville', 'tater', 'coldstorage'
  %
  % The at-bat is one d100 roll (two d10s, read as 00-99). On every
  % park and every split:
  %   00-03    PB/WP check
  %   04-99    the park's table for this split, in this order:
  %              K  ->  BIP  ->  BB  ->  HR
  %            (BIP is whatever is left over, so the hitter-friendly
  %            results sit at the top of the roll)
  %
  % Each split is named PITCHER-hand v BATTER-hand: RvR, RvL, LvR, LvL
  % (RvL = right-handed pitcher facing a left-handed batter).
  %
  % You only type how many of the 96 slots go to K, BB and HR; BIP
  % (ball in play -> Liveball portion) fills the rest. The tables are
  % stored as park.RvR etc. (1x100 cell arrays; the roll 00-99 is
  % looked up at index roll+1)
  % and the printable ranges are in park.ranges.RvR etc.
  %
  % The K, BB and HR results are "possibilities": batter and pitcher
  % d20 check, else Liveball.
  %
  % Neutral reference: PBWP 4, K 60, BB 15, HR 15, BIP 6. With the
  % league-average skills in generate_player that gives roughly
  % K 25%, BB 8.5%, HR 3.5% per PA (the old d8/d12 mix, in one roll).

  PBWP_SLOTS = 4;

  % counts = [K BB HR]   (must total 96 or less; the rest is BIP)
  switch lower(name)
    case 'spudsville'
      % Neutral park: same mix in every split.
      park.name = 'Spudsville Park';
      counts.RvR = [60 15 15];
      counts.RvL = [60 15 15];
      counts.LvR = [60 15 15];
      counts.LvL = [60 15 15];

    case 'tater'
      % Short right-field porch: left-handed batters (RvL, LvL) get
      % extra HR slots, most of all against right-handed pitchers.
      park.name = 'Tater Terrace';
      counts.RvR = [60 15 15];
      counts.RvL = [52 14 26];
      counts.LvR = [60 15 15];
      counts.LvL = [56 14 21];

    case 'coldstorage'
      % Cavernous, pitcher-friendly: extra K slots, almost no HR
      % (none at all in the RvR, LvR and LvL splits).
      park.name = 'Cold Storage Field';
      counts.RvR = [72 16 0];
      counts.RvL = [66 16 6];
      counts.LvR = [72 16 0];
      counts.LvL = [72 16 0];

    otherwise
      error('get_park: unknown park ''%s'' (try spudsville, tater, coldstorage)', name);
  end

  splits = {'RvR','RvL','LvR','LvL'};
  for i = 1:numel(splits)
    sp = splits{i};
    c = counts.(sp);
    if any(c < 0) || sum(c) > 100 - PBWP_SLOTS
      error('get_park: %s %s counts [%d %d %d] must be >= 0 and total <= %d', ...
            park.name, sp, c(1), c(2), c(3), 100 - PBWP_SLOTS);
    end
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
