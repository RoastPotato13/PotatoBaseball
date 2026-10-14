% DEMO_ATBATS  Quick smoke test for the at-bat engine.
%
% Generates one batter, one pitcher and a park, runs N simulated
% plate appearances with a roll-by-roll rolls, then a results tally.
% Finishes with a larger silent run (M PAs) to sanity check rates, plus
% a batted-ball table (fielder x result) for the balls in play, with
% how often each fielder faced a fielding check and made the play.

clear;

N = 10;       % verbose plate appearances
M = 20000;    % silent plate appearances for the rate check
park_name = 'random';   % 'spudsville', 'tater', 'coldstorage', 'random'

batter  = generate_player('Spud Malone', 'batter');
pitcher = generate_player('Russet Grimes', 'pitcher');
park    = get_park(park_name);

print_park(park);
printf('\n');

printf('--- Matchup at %s (%sv%s, pitcher v batter) ---\n', park.name, pitcher.hand, batter.hand);
printf('%s (bats %s)   K:%d BB:%d HR:%d\n', ...
  batter.name, batter.hand, batter.K, batter.BB, batter.HR);
printf('%s (throws %s) K:%d BB:%d HR:%d\n\n', ...
  pitcher.name, pitcher.hand, pitcher.K, pitcher.BB, pitcher.HR);

print_card(pitcher);
print_card(batter);
printf('\n');

labels = {'K','BB','HR','1B','2B','OUT','PU'};

% Batted-ball table: rows = fielder the ball ended up with (a hit that gets
% past an infielder counts for the outfielder), columns = result.
% PU is tracked on its own since it has no fielder.
% chk / made: fielding checks faced by each fielder (whether or not the
% ball then got through) and how many he passed, i.e. plays made.
fielders = {'1B','2B','3B','SS','LF','CF','RF'};
results  = {'OUT','1B','2B'};
bb   = zeros(numel(fielders), numel(results));
chk  = zeros(1, numel(fielders));
made = zeros(1, numel(fielders));
pu_count = 0;

for i = 1:N
  [outcome, rolls] = resolve_at_bat(batter, pitcher, park);
  printf('AB %2d: %s\n', i, outcome);
  for j = 1:numel(rolls)
    printf('       %s\n', rolls{j});
  end
end

% --- Rate check over many PAs with this matchup ---
counts = zeros(1, numel(labels));
for i = 1:M
  [outcome, ~, ball] = resolve_at_bat(batter, pitcher, park);
  idx = find(strcmp(labels, outcome));
  counts(idx) = counts(idx) + 1;

  if ~isempty(ball)
    if strcmp(ball.kind, 'PU')
      pu_count = pu_count + 1;
    else
      r = find(strcmp(fielders, ball.pos));
      c = find(strcmp(results, outcome));
      bb(r, c) = bb(r, c) + 1;
      if strcmp(ball.check, 'FIELD')
        k = find(strcmp(fielders, ball.check_pos));
        chk(k) = chk(k) + 1;
        if ball.check_passed
          made(k) = made(k) + 1;
        end
      end
    end
  end
end

printf('\n--- Outcome rates over %d PA ---\n', M);
for i = 1:numel(labels)
  printf('%-8s: %5.1f%%\n', labels{i}, 100 * counts(i) / M);
end

% --- Batted-ball table ---
total_bip = sum(bb(:)) + pu_count;
printf('\n--- Batted balls by fielder (%d balls in play) ---\n', total_bip);
printf('%-6s', '');
for c = 1:numel(results)
  printf('%7s', results{c});
end
printf('%8s%9s%7s%8s\n', 'Total', 'Checks', 'Made', 'Made%');
for r = 1:numel(fielders)
  printf('%-6s', fielders{r});
  for c = 1:numel(results)
    printf('%7d', bb(r, c));
  end
  if chk(r) > 0
    ps = sprintf('%.0f%%', 100 * made(r) / chk(r));
  else
    ps = '-';
  end
  printf('%8d%9d%7d%8s\n', sum(bb(r, :)), chk(r), made(r), ps);
end
printf('%-6s%7s%7s%7s%8d\n', 'PU', '', '', '', pu_count);
printf('%-6s', 'Total');
for c = 1:numel(results)
  printf('%7d', sum(bb(:, c)));
end
if sum(chk) > 0
  ps = sprintf('%.0f%%', 100 * sum(made) / sum(chk));
else
  ps = '-';
end
printf('%8d%9d%7d%8s\n', total_bip, sum(chk), sum(made), ps);
printf('(Checks = fielding checks faced; Made = passed, so the play was an out.)\n');
