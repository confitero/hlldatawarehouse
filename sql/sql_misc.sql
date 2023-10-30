USE hlldw;

SELECT COUNT(*) FROM player;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

SELECT COUNT(*) FROM playerstats;
SELECT SUM(kills) FROM killsbyplayer;
SELECT SUM(deaths) FROM deathsbyplayer;

SELECT SUM(kills) FROM weaponkillsbyplayer;
SELECT SUM(Deaths) FROM weapondeathsbyplayer;
SELECT SUM(kills) FROM playerstats;
SELECT SUM(deaths) FROM playerstats;

SELECT * FROM player LIMIT 10;

SELECT *
FROM playerstats a, playerstats b WHERE a.MatchID<>b.matchID AND a.SteamID=b.SteamID

SELECT *
FROM playerstats a
WHERE a.MatchID=5 AND a.SteamID NOT IN (SELECT b.SteamID from playerstats b WHERE b.MatchID=6)


#SELECT mapID FROM map WHERE MapKey='stmereeglise_warfare_night'


--Ver mismo jugador con SteamID y distinto nick en partidas cargadas
SELECT distinct a.Player,b.Player from
playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player AND a.MatchID<b.matchID


SELECT * FROM playernicks
SELECT * FROM playerstats where matchID=52 LIMIT 10

SELECT distinct a.MatchID,a.Player,a.PlayerClanID,a.PlayerClanTag,d.Side,a.KillsByWeapons FROM playerstats a, gamematch b, weaponkillsbyplayer c, weapon d WHERE a.MatchID=b.MatchID AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;

SELECT * FROM weaponkillsbyplayer a WHERE a.weapon  not IN (SELECT DISTINCT weapon FROM weapon);
SELECT DISTINCT Weapon FROM weaponkillsbyplayer a WHERE a.weapon NOT IN (SELECT DISTINCT weapon FROM weapon);

SELECT * from weaponkillsbyplayer where matchID IN (12,27,30,32)