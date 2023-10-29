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

SELECT * FROM playerstats WHERE DWPlayerID='76561198814425011' AND matchID=10;
SELECT * FROM weaponkillsbyplayer WHERE Player='-L- [129]Nemudo Borr' AND matchID=10;
SELECT * FROM weapondeathsbyplayer WHERE Player='-L- [129]Nemudo Borr' AND matchID=10;
SELECT * FROM killsbyplayer WHERE killer='-L- [129]Nemudo Borr' AND matchID=10;
SELECT * FROM deathsbyplayer WHERE killer='-L- [129]Nemudo Borr' AND matchID=10;