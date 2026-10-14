function contact = generate_contact(type)
  % GENERATE_CONTACT Build a player's 100-slot batted-ball card.
  %
  %   contact = generate_contact(type)   type: 'batter', 'pitcher',
  %                                      or 'league' (no spread, for
  %                                      checking the league-average card)
  %
  % Called by generate_player. Used by liveball.m.
  %
  % The card is a d100 chart (00-99) of 11 definitive results. Pull/Opp
  % is relative to the batter's hand:
  %   PU            pop-up (counts like a K)
  %   GBO_P  GBO_O  ground-ball out
  %   FBO_P  FBO_O  fly-ball out
  %   GB1_P  GB1_O  single on a ground ball
  %   FB1_P  FB1_O  single on a fly ball
  %   FB2_P  FB2_O  double (always a fly ball)
  %
  % Pipeline:
  %   1. Each player draws FINAL per-BIP rates around the league average:
  %      PU, GB1, FB1, FB2, and the ground-ball share of all BIP.
  %      "Final" = after fielding/ballpark checks have done their work.
  %   2. INFLATE the hit rates: some card hits become outs when a check
  %      passes, so card rate = final rate / survival. Survival comes
  %      from the d20 tables and the check pass rate in liveball_tables.
  %   3. Outs fill what's left: GBO = GB total - GB1, and
  %      FBO = (1 - PU - GB total) - FB1 - FB2.
  %   4. Split each category into Pull/Opp, with a per-player pull shift.
  %   5. Round to 100 slots (largest remainder).

  % ======================================================================
  % LEAGUE AVERAGES -- tune here
  % ======================================================================
  % FINAL rates, as a share of all balls in play (after checks).
  % These defaults give BABIP (excluding HR) of about .295.
  LG_PU  = 0.070;    % pop-ups
  LG_GB1 = 0.105;    % singles on ground balls
  LG_FB1 = 0.120;    % singles on fly balls
  LG_FB2 = 0.070;    % doubles

  % Share of ALL balls in play that start as a ground ball (outs plus
  % ground-ball hits, before checks). Fly balls get what's left after
  % PU and GB.
  LG_GB_SHARE = 0.43;

  % Pull share (the rest is Opp) within each category:
  PULL_GBO = 0.55;
  PULL_FBO = 0.48;
  PULL_GB1 = 0.55;
  PULL_FB1 = 0.48;
  PULL_FB2 = 0.50;

  % ======================================================================
  % SPREADS (std dev), same order as the rates above:
  % [PU  GB1  FB1  FB2  GB_SHARE]. Fractions of all BIP.
  % Batters swing hit rates more than pitchers do.
  % ======================================================================
  BATTER_SD  = [0.020 0.015 0.015 0.010 0.050];
  PITCHER_SD = [0.015 0.007 0.007 0.005 0.060];

  % Pull shift: every category's pull share moves by one draw of this
  % size. Batters vary a lot, pitchers barely control direction.
  BATTER_SD_PULL  = 0.07;
  PITCHER_SD_PULL = 0.02;
  MIN_PULL = 0.05;
  MAX_PULL = 0.95;

  CARD_SLOTS = 100;
  % ======================================================================

  if strcmpi(type, 'batter')
    sd = BATTER_SD;   sd_pull = BATTER_SD_PULL;
  elseif strcmpi(type, 'pitcher')
    sd = PITCHER_SD;  sd_pull = PITCHER_SD_PULL;
  elseif strcmpi(type, 'league')
    sd = zeros(1, 5); sd_pull = 0;
  else
    error('generate_contact: type must be ''batter'', ''pitcher'' or ''league''');
  end

  % --- survival of a card hit through the fielding / ballpark checks ---
  T = liveball_tables();
  surv_gb = 1 - check_fraction(T.GB_HIT) * T.pass_rate;
  surv_fb = 1 - check_fraction(T.FB_HIT) * T.pass_rate;

  % --- 1. the player's final rates ---
  rate = max(0, [LG_PU LG_GB1 LG_FB1 LG_FB2 LG_GB_SHARE] + sd .* randn(1, 5));
  pu        = rate(1);
  gb1_final = rate(2);
  fb1_final = rate(3);
  fb2_final = rate(4);
  gb_total  = rate(5);

  % --- 2. inflate hits to card rates ---
  gb1 = gb1_final / surv_gb;
  fb1 = fb1_final / surv_fb;
  fb2 = fb2_final / surv_fb;

  % --- 3. outs take the remainder of each ball type ---
  gbo = max(0, gb_total - gb1);
  fbo = max(0, (1 - pu - gb_total) - fb1 - fb2);

  % --- 4. Pull/Opp split ---
  cat_share = [gbo fbo gb1 fb1 fb2];            % GBO FBO GB1 FB1 FB2
  pull = [PULL_GBO PULL_FBO PULL_GB1 PULL_FB1 PULL_FB2] + sd_pull * randn();
  pull = min(MAX_PULL, max(MIN_PULL, pull));

  % [PU GBO_P GBO_O FBO_P FBO_O GB1_P GB1_O FB1_P FB1_O FB2_P FB2_O]
  share = zeros(1, 11);
  share(1) = pu;
  for k = 1:5
    share(2*k)     = cat_share(k) * pull(k);
    share(2*k + 1) = cat_share(k) * (1 - pull(k));
  end
  share = share / sum(share);

  % --- 5. round to slots and build the d100 table ---
  counts = apportion(share, CARD_SLOTS);

  labels = {'PU', 'GBO_P', 'GBO_O', 'FBO_P', 'FBO_O', ...
            'GB1_P', 'GB1_O', 'FB1_P', 'FB1_O', 'FB2_P', 'FB2_O'};
  card = cell(1, CARD_SLOTS);
  range_cell = {};
  pos = 1;
  for i = 1:numel(labels)
    if counts(i) == 0
      continue;
    end
    lo = pos;
    hi = pos + counts(i) - 1;
    card(lo:hi) = {labels{i}};
    range_cell{end+1} = sprintf('%s %02d-%02d', labels{i}, lo - 1, hi - 1);
    pos = hi + 1;
  end

  contact.labels     = labels;
  contact.share      = share;
  contact.counts     = counts;
  contact.card       = card;            % 1x100 cell, index = d100 + 1
  contact.range_cell = range_cell;
  contact.final      = struct('PU', pu, 'GB1', gb1_final, 'FB1', fb1_final, ...
                              'FB2', fb2_final, 'GB_SHARE', gb_total);
end

function f = check_fraction(tbl)
  % Share of a d20 table's faces that trigger a fielding/ballpark check.
  n = 0;
  for i = 1:numel(tbl)
    if strncmp(tbl{i}, 'FIELD_', 6) || strncmp(tbl{i}, 'PARK_', 5)
      n = n + 1;
    end
  end
  f = n / numel(tbl);
end

function c = apportion(share, n)
  % Largest-remainder rounding: integer counts that sum to exactly n.
  raw = share * n;
  c = floor(raw);
  short = n - sum(c);
  [~, order] = sort(raw - c, 'descend');
  c(order(1:short)) = c(order(1:short)) + 1;
end
