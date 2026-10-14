function T = liveball_tables()
  % LIVEBALL_TABLES Shared d20 branch tables and check constants.
  %
  %   T = liveball_tables()
  %
  % Used by liveball.m (to resolve a ball in play) and generate_contact.m
  % (to inflate card hit rates so the FINAL league hit rates come out
  % right after fielding/ballpark checks convert some hits to outs).
  % Edit the tables here and both files stay in sync.
  %
  % Each table maps a d20 roll (1-20) to an action 'VERB_ROLE':
  %   OUT_xx    automatic out, fielded by role xx
  %   HIT_xx    the hit stands, ball goes to role xx (no check)
  %   FIELD_xx  fielding check by role xx: d20 <= skill -> out, else hit
  %   FIELD_xx_yy  same, but for an infielder: if the check fails the ball
  %             gets through to role yy in the outfield
  %   PARK_xx   ballpark check: d20 <= park skill -> out, else hit.
  %             CO uses its own corner's skill (LF or RF); CF uses the
  %             LF or RF skill for the side the ball was hit to.
  % Roles: MI = middle infielder (SS/2B), CI = corner infielder (3B/1B),
  %        CO = corner outfielder (LF/RF), CF = center fielder.
  % Pull/Opp plus the batter's hand turns a role into a position
  % (see position_for in liveball.m).

  % Skill 10 on a d20 passes 50% of the time. Every check uses this
  % default until real fielders exist.
  T.default_skill = 10;
  T.pass_rate     = T.default_skill / 20;

  % Single on a ground ball
  % A failed infield check gets through: 1-2 up the middle to CF, 3-5 to
  % the corner outfielder on that side.
  T.GB_HIT = fill20({ 1,  2, 'FIELD_MI_CF'; ...
                      3,  3, 'FIELD_MI_CO'; ...
                      4,  5, 'FIELD_CI_CO'; ...
                      6, 14, 'HIT_CO';   ...
                     15, 20, 'HIT_CF' });

  % 1B or 2B on a fly ball
  T.FB_HIT = fill20({ 1,  3, 'FIELD_CO'; ...
                      4,  5, 'FIELD_CF'; ...
                      6,  8, 'PARK_CO';  ...
                      9, 10, 'PARK_CF';  ...
                     11, 16, 'HIT_CO';   ...
                     17, 20, 'HIT_CF' });

  % Outs (no checks). TODO: slow grounder for GB_OUT, likely using a
  % 4th d20.
  T.GB_OUT = fill20({ 1, 12, 'OUT_MI'; ...
                     13, 20, 'OUT_CI' });
  T.FB_OUT = fill20({ 1, 12, 'OUT_CO'; ...
                     13, 20, 'OUT_CF' });
end

function tbl = fill20(spec)
  % Expand {lo, hi, action; ...} into a 1x20 cell (index = d20 roll).
  tbl = cell(1, 20);
  for k = 1:size(spec, 1)
    tbl(spec{k,1}:spec{k,2}) = {spec{k,3}};
  end
  if any(cellfun(@isempty, tbl))
    error('liveball_tables: a d20 table does not cover 1-20');
  end
end
