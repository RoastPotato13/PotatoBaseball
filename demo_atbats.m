% DEMO_ATBATS  Quick smoke test for the at-bat engine.
%
% Generates one batter, one pitcher, runs N simulated plate
% appearances, prints play-by-play, then a results tally.

clear; clc;

N = 20;

batter  = generate_player('Spud Malone', 'batter');
pitcher = generate_player('Russet Grimes', 'pitcher');

printf('--- Matchup ---\n');
printf('%s (batter)  contact:%d power:%d eye:%d speed:%d\n', ...
  batter.name, batter.contact, batter.power, batter.eye, batter.speed);
printf('%s (pitcher) stuff:%d control:%d\n\n', ...
  pitcher.name, pitcher.stuff, pitcher.control);

results = cell(1, N);
for i = 1:N
  outcome = resolve_at_bat(batter, pitcher);
  results{i} = outcome;
  printf('AB %2d: %s\n', i, outcome);
end

% --- Tally ---
labels = {'K','BB','GO','FO','LO','1B','2B','3B','HR'};
counts = zeros(1, numel(labels));
for i = 1:N
  idx = find(strcmp(labels, results{i}));
  counts(idx) = counts(idx) + 1;
end

printf('\n--- Tally over %d PA ---\n', N);
for i = 1:numel(labels)
  printf('%-3s: %d\n', labels{i}, counts(i));
end

hits = counts(6) + counts(7) + counts(8) + counts(9); % 1B+2B+3B+HR
ab = N - counts(2); % subtract walks from at-bats (rough, ignores HBP/SF)
if ab > 0
  printf('\nApprox AVG (hits / (PA-BB)): %.3f\n', hits / ab);
end
