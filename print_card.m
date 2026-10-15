function print_card(player)
  % PRINT_CARD Print a player's d100 batted-ball card.
  %
  %   print_card(batter)
  %
  % Codes: PU pop-up | GBO/FBO ground/fly-ball out | GBC ground-ball check
  % FB1 single on a fly ball | FB2 double. _P = Pull, _O = Opp.

  c = player.contact;
  printf('%s (%s) batted-ball card\n', player.name, player.type);
  r = c.range_cell;
  for i = 1:numel(r)
    if mod(i - 1, 4) == 0
      printf('  ');
    end
    printf('%-15s', r{i});
    if mod(i, 4) == 0 || i == numel(r)
      printf('\n');
    end
  end
end
