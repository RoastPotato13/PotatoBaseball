function park = get_park(name)
  % GET_PARK Return a ballpark by name.
  %
  %   park = get_park(name)   name: 'spudsville', 'tater', 'coldstorage',
  %                           or 'random'
  %
  % Preset parks give park factors [K BB HR] for right-handed (R) and
  % left-handed (L) batters, 1 = league average. Pitcher hand only
  % enters through the league-wide platoon splits in generate_park.

  switch lower(name)
    case 'spudsville'
      % Neutral park (explicit 1s, since omitting factors randomizes).
      factor.R = [1 1 1];
      factor.L = [1 1 1];
      park = generate_park('Spudsville Park', factor);

    case 'tater'
      % Short right-field porch: lefty batters get far more HR, fewer K.
      factor.R = [1.00 1.00 1.00];
      factor.L = [0.92 0.95 1.60];
      park = generate_park('Tater Terrace', factor);

    case 'coldstorage'
      % Cavernous, pitcher-friendly: more K and BB, HR cut hard.
      factor.R = [1.20 1.07 0.35];
      factor.L = [1.20 1.07 0.35];
      park = generate_park('Cold Storage Field', factor);

    case 'random'
      park = generate_park('Random Park');

    otherwise
      error('get_park: unknown park ''%s'' (try spudsville, tater, coldstorage, random)', name);
  end
end
