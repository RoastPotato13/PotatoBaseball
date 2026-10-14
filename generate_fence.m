function fence = generate_fence(key)
  % GENERATE_FENCE Ballpark-check skills for a park.
  %
  %   fence = generate_fence(key)
  %   key : 'spudsville', 'tater', 'coldstorage' or 'random'
  %
  % fence.LF.B1, fence.LF.B2, fence.RF.B1, fence.RF.B2: d20 skills for
  % a single (B1) or double (B2) hit toward that side of the field.
  % 10 = league average. A ballpark check passes on d20 <= skill and a
  % pass is an OUT, so a HIGHER skill means the park holds more hits in.
  %
  % The side comes from where the ball goes (pull/opp plus batter
  % hand), not from batter handedness itself. A ball fielded by the CF
  % still counts as hit to the left or right side of center, so it uses
  % the LF or RF skill; there is no separate CF skill.
  %
  % Called from get_park. Preset values are placeholders.

  % ======================================================================
  DEFAULT   = 10;
  PARK_SD   = 1.0;    % random parks: park-wide shift (hitter vs pitcher park)
  FIELD_SD  = 1.5;    % random parks: extra noise per side and hit type
  SKILL_MIN = 1;
  SKILL_MAX = 20;
  % ======================================================================

  positions = {'LF', 'RF'};
  hit_types = {'B1', 'B2'};

  base = DEFAULT * ones(2, 2);     % rows LF RF, columns B1 B2

  switch lower(key)
    case 'spudsville'
      % neutral: all 10
    case 'tater'
      base(2, :) = [9 8];          % short right-field porch: hits stand more
    case 'coldstorage'
      base(:, :) = 12;             % cavernous: more hits held in
    case 'random'
      base = base + PARK_SD * randn() + FIELD_SD * randn(2, 2);
    otherwise
      error('generate_fence: unknown park key ''%s''', key);
  end

  base = max(SKILL_MIN, min(SKILL_MAX, round(base)));

  for i = 1:2
    for j = 1:2
      fence.(positions{i}).(hit_types{j}) = base(i, j);
    end
  end
end
