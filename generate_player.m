function player = generate_player(name, type)
  % GENERATE_PLAYER Create a randomly-rated batter or pitcher.
  %
  %   player = generate_player(name, type)
  %
  %   name : string, player's name
  %   type : 'batter' or 'pitcher'
  %
  % Ratings use a 20-80 scouting scale (55 = league average),
  % generated as a rounded normal distribution so most players
  % cluster near average with occasional stars/scrubs.

  player.name = name;
  player.type = type;

  if strcmpi(type, 'batter')
    player.contact = clamp_rating(round(normrnd_local(55, 12)));
    player.power   = clamp_rating(round(normrnd_local(55, 15)));
    player.eye     = clamp_rating(round(normrnd_local(55, 12)));
    player.speed   = clamp_rating(round(normrnd_local(55, 15)));
  elseif strcmpi(type, 'pitcher')
    player.stuff   = clamp_rating(round(normrnd_local(55, 12)));
    player.control = clamp_rating(round(normrnd_local(55, 12)));
  else
    error('generate_player: type must be ''batter'' or ''pitcher''');
  end
end

function r = clamp_rating(r)
  r = max(20, min(80, r));
end

function val = normrnd_local(mu, sigma)
  % Avoids a dependency on the statistics package.
  val = mu + sigma * randn();
end
