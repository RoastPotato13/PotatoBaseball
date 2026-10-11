% DEMO_ATBATS  Quick smoke test for the at-bat engine.
%
% Generates one batter, one pitcher and a park, runs N simulated
% plate appearances with a roll-by-roll rolls, then a results tally.
% Finishes with a larger silent run (M PAs) to sanity check rates.

clear; clc;

N = 10;       % verbose plate appearances
M = 20000;    % silent plate appearances for the rate check
park_name = 'tater';   % 'spudsville', 'tater', 'coldstorage'

batter  = generate_player('Spud Malone', 'batter');
pitcher = generate_player('Russet Grimes', 'pitcher');
park    = get_park(park_name);

printf('--- Matchup at %s (%sv%s, pitcher v batter) ---\n', park.name, pitcher.hand, batter.hand);
printf('%s (bats %s)   K:%d BB:%d HR:%d\n', ...
  batter.name, batter.hand, batter.K, batter.BB, batter.HR);
printf('%s (throws %s) K:%d BB:%d HR:%d\n\n', ...
  pitcher.name, pitcher.hand, pitcher.K, pitcher.BB, pitcher.HR);

labels = {'K','BB','HR','1B','2B','3B','PBWP','LIVEBALL'};

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
  outcome = resolve_at_bat(batter, pitcher, park);
  idx = find(strcmp(labels, outcome));
  counts(idx) = counts(idx) + 1;
end

printf('\n--- Outcome rates over %d PA ---\n', M);
for i = 1:numel(labels)
  printf('%-8s: %5.1f%%\n', labels{i}, 100 * counts(i) / M);
end
