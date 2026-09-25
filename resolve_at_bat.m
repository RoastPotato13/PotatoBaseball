function [outcome, probs] = resolve_at_bat(batter, pitcher)
  % RESOLVE_AT_BAT Simulate one plate appearance.
  %
  %   [outcome, probs] = resolve_at_bat(batter, pitcher)
  %
  %   outcome : string, one of
  %             'K','BB','GO','FO','LO','1B','2B','3B','HR'
  %   probs   : struct of final probabilities used (for debugging/tuning)
  %
  % Approach: start from rough league-average rates, then nudge each
  % rate based on how far the batter/pitcher ratings sit from 55
  % (league average on the 20-80 scale). Normalize so everything
  % sums to 1, then draw a single uniform random number and walk the
  % cumulative distribution.

  % --- League-average baseline (very roughly MLB-shaped) ---
  base.K  = 0.22;
  base.BB = 0.08;
  base.GO = 0.17;
  base.FO = 0.17;
  base.LO = 0.06;
  base.HB1 = 0.15;  % single
  base.HB2 = 0.05;  % double
  base.HB3 = 0.005; % triple
  base.HR  = 0.035;

  % --- Scale factors: -1 .. +1 roughly, from 20-80 rating vs 55 avg ---
  bc = (batter.contact - 55) / 25;  % batter contact
  bp = (batter.power   - 55) / 25;  % batter power
  be = (batter.eye     - 55) / 25;  % batter plate discipline
  ps = (pitcher.stuff   - 55) / 25; % pitcher stuff (drives Ks)
  pc = (pitcher.control - 55) / 25; % pitcher control (limits BB)

  % --- Adjust strikeout rate: pitcher stuff up, batter contact down ---
  k = base.K + 0.09 * ps - 0.07 * bc;

  % --- Adjust walk rate: batter eye up, pitcher control down (i.e. wild) ---
  bb = base.BB + 0.05 * be - 0.05 * pc;

  % --- Adjust extra-base power: batter power up, pitcher stuff down ---
  hr  = base.HR  + 0.04 * bp - 0.02 * ps;
  h2  = base.HB2 + 0.02 * bp - 0.01 * ps;
  h3  = max(base.HB3 + 0.003 * (batter.speed - 55), 0.001);

  % --- Singles get a boost from contact, slight boost from speed (legs out) ---
  h1 = base.HB1 + 0.05 * bc + 0.01 * ((batter.speed - 55) / 25);

  % --- Outs in play absorb whatever's left; split GO/FO/LO roughly as base ---
  go = base.GO;
  fo = base.FO;
  lo = base.LO;

  % Clamp everything non-negative before normalizing
  fields = {'k','bb','go','fo','lo','h1','h2','h3','hr'};
  vals = [k, bb, go, fo, lo, h1, h2, h3, hr];
  vals = max(vals, 0.001);

  total = sum(vals);
  vals = vals / total;

  probs.K  = vals(1);
  probs.BB = vals(2);
  probs.GO = vals(3);
  probs.FO = vals(4);
  probs.LO = vals(5);
  probs.HB1 = vals(6);
  probs.HB2 = vals(7);
  probs.HB3 = vals(8);
  probs.HR = vals(9);

  labels = {'K','BB','GO','FO','LO','1B','2B','3B','HR'};
  cume = cumsum(vals);
  roll = rand();
  idx = find(roll <= cume, 1, 'first');
  outcome = labels{idx};
end
