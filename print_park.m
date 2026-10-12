function print_park(park)
  % PRINT_PARK Print a park's d100 ranges for each split.
  %
  %   print_park(get_park('tater'))
  %
  % Output is plain text for now; other printed formats can be added
  % later by reading park.ranges.(split) and park.(split).

  splits = {'RvR','RvL','LvR','LvL'};
  printf('%s  (d100)\n', park.name);
  for i = 1:numel(splits)
    printf('  %s:  %s\n', splits{i}, park.ranges.(splits{i}));
  end
end
