function print_park(park)
  % PRINT_PARK Print a park card: factors, combined splits, d100 ranges.
  %
  %   print_park(get_park('tater'))
  %
  % Plain text for now; other formats can be added later by reading
  % park.factor, park.split, park.ranges and park.(split).

  splits = {'RvR','RvL','LvR','LvL'};
  printf('%s\n', park.name);

  printf('  Park factors (1.00 = league average)\n');
  printf('               K     BB     HR\n');
  printf('    vs RHB  %5.2f  %5.2f  %5.2f\n', ...
    park.factor.R.K, park.factor.R.BB, park.factor.R.HR);
  printf('    vs LHB  %5.2f  %5.2f  %5.2f\n', ...
    park.factor.L.K, park.factor.L.BB, park.factor.L.HR);

  printf('  Combined splits (league platoon x park factor) and d100\n');
  for i = 1:numel(splits)
    sp = splits{i};
    printf('    %s  K %4.2f  BB %4.2f  HR %4.2f   %s\n', sp, ...
      park.split.(sp).K, park.split.(sp).BB, park.split.(sp).HR, ...
      park.ranges.(sp));
  end

  printf('  Ballpark check skills (d20, 10 = avg, higher = more outs)\n');
  printf('               LEFT    RIGHT\n');
  printf('    1B       %3d   %3d\n', park.fence.LF.B1, park.fence.RF.B1);
  printf('    2B       %3d   %3d\n', park.fence.LF.B2, park.fence.RF.B2);
end
