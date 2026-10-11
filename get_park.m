function park = get_park(name)
  % GET_PARK Return a ballpark and its four handedness split tables.
  %
  %   park = get_park(name)        name: 'spudsville', 'tater', 'coldstorage'
  %
  % Each park has four tables, one per split, named PITCHER-hand v
  % BATTER-hand:  RvR, RvL, LvR, LvL   (e.g. RvL = right-handed
  % pitcher facing a left-handed batter).
  %
  % Each table is a 1x12 cell array indexed by the d12 Ballpark/Split
  % roll:
  %   slot 1       always 'PBWP'  (leads to the PB/WP check)
  %   slots 2-12   the park's results, each one of:
  %                  'K','BB','HR'  a possibility: batter and pitcher
  %                                 d20 check, else Liveball
  %                  'BIP'          ball in play -> Liveball portion
  %
  % Park character comes from how many slots each split gives to K,
  % BB and HR. A park that is stingy with something (say HR in the
  % LvL split) just gets BIP in those slots instead.
  %
  % A "neutral" table here is K x5, BB x1, HR x1, BIP x4 in slots 2-12,
  % which roughly mirrors the standard deadball d8 rates.

  switch lower(name)
    case 'spudsville'
      % Neutral park: same mix in every split.
      park.name = 'Spudsville Park';
      park.RvR = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.RvL = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.LvR = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.LvL = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};

    case 'tater'
      % Short right-field porch: left-handed batters (RvL, LvL) get
      % extra HR slots, most of all against right-handed pitchers.
      park.name = 'Tater Terrace';
      park.RvR = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.RvL = {'PBWP','K','K','K','K','K','BB','HR','HR','HR','BIP','BIP'};
      park.LvR = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.LvL = {'PBWP','K','K','K','K','K','BB','HR','HR','BIP','BIP','BIP'};

    case 'coldstorage'
      % Cavernous, pitcher-friendly: extra K slots, almost no HR
      % (none at all in the LvL, RvR and LvR splits).
      park.name = 'Cold Storage Field';
      park.RvR = {'PBWP','K','K','K','K','K','K','BB','BIP','BIP','BIP','BIP'};
      park.RvL = {'PBWP','K','K','K','K','K','BB','HR','BIP','BIP','BIP','BIP'};
      park.LvR = {'PBWP','K','K','K','K','K','K','BB','BIP','BIP','BIP','BIP'};
      park.LvL = {'PBWP','K','K','K','K','K','K','BB','BIP','BIP','BIP','BIP'};

    otherwise
      error('get_park: unknown park ''%s'' (try spudsville, tater, coldstorage)', name);
  end

  % Sanity check the tables so a typo can't silently break a roll.
  splits = {'RvR','RvL','LvR','LvL'};
  allowed = {'K','BB','HR','BIP'};
  for i = 1:numel(splits)
    t = park.(splits{i});
    if numel(t) ~= 12
      error('get_park: %s %s table needs 12 entries, has %d', ...
            park.name, splits{i}, numel(t));
    end
    if ~strcmp(t{1}, 'PBWP')
      error('get_park: %s %s slot 1 must be ''PBWP''', park.name, splits{i});
    end
    for s = 2:12
      if ~any(strcmp(t{s}, allowed))
        error('get_park: %s %s slot %d has invalid result ''%s''', ...
              park.name, splits{i}, s, t{s});
      end
    end
  end
end
