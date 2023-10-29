-- ### FIX DATA SCRIPTS FOR HLL DATAWAREHOUSE

#FIX player nick / Normalizar nombre jugador
UPDATE playerstats SET player=TRIM(player);
UPDATE weaponkillsbyplayer SET player=TRIM(player);
UPDATE weaponkillsbyplayer SET weapon=TRIM(weapon);
UPDATE killsbyplayer SET killer=TRIM(killer);
UPDATE killsbyplayer SET victim=TRIM(victim);
UPDATE deathsbyplayer SET killer=TRIM(killer);
UPDATE deathsbyplayer SET victim=TRIM(victim);

#FILL field playerstats.PlayerTag and playerstats.ClanID from embed TAG in player nick RCON json stats
-- SELECT distinct x.player,y.clantag,z.ClanName AS CompClan FROM playerstats x, clantag y, clan z where locate(y.clantag,x.Player)>0 AND y.ClanID=z.ClanID
UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0

#Insert/create new players from loaded player stats
INSERT INTO player (SteamID,Rank) SELECT DISTINCT SteamID,0 FROM playerstats WHERE SteamID>0 AND SteamID NOT IN (SELECT DISTINCT SteamID FROM player)


## Ver si hay jugadores en stats con nicks secundarios que corregir a nivel GLOBAL:
START TRANSACTION
SAVEPOINT puntoX1
SELECT * FROM playerstats a, playernicktemp b WHERE a.Player=b.nick;
UPDATE playerstats a, playernicktemp b SET a.Player=b.mainnick  WHERE a.Player=b.nick;
SELECT * FROM killsbyplayer a, playernicktemp b WHERE a.Killer=b.nick;
UPDATE killsbyplayer a, playernicktemp b SET a.Killer=b.mainnick  WHERE a.Killer=b.nick;
SELECT * FROM weaponkillsbyplayer a, playernicktemp b WHERE a.Player=b.nick;
UPDATE weaponkillsbyplayer a, playernicktemp b SET a.Player=b.mainnick  WHERE a.Player=b.nick;
SELECT * FROM deathsbyplayer a, playernicktemp b WHERE a.Victim=b.nick;
UPDATE deathsbyplayer a, playernicktemp b SET a.Victim=b.mainnick  WHERE a.Victim=b.nick;
SELECT * FROM killsbyplayer a, playernicktemp b WHERE a.Victim=b.nick;
UPDATE killsbyplayer a, playernicktemp b SET a.Victim=b.mainnick  WHERE a.Victim=b.nick;
SELECT * FROM deathsbyplayer a, playernicktemp b WHERE a.Killer=b.nick;
UPDATE deathsbyplayer a, playernicktemp b SET a.Killer=b.mainnick  WHERE a.Killer=b.nick;
--COMMIT
ROLLBACK TO puntoX1
RELEASE SAVEPOINT puntoX1

#COMPROBAR QUE TODOS COINCIDEN
SET @MatchID=10;
SELECT COUNT(Distinct SteamID) FROM player;
SELECT COUNT(DISTINCT SteamID) FROM playerstats;
SELECT SUM(Kills),SUM(Deaths),SUM(tks),SUM(Kills)+SUM(tks) FROM playerstats WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Deaths) FROM weapondeathsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID;

SELECT * FROM playerstats WHERE MatchID=@MatchID;
SELECT * FROM weaponkillsbyplayer WHERE MatchID=@MatchID;
SELECT * FROM weapondeathsbyplayer WHERE MatchID=@MatchID;
SELECT * FROM killsbyplayer WHERE MatchID=@MatchID;
SELECT * FROM deathsbyplayer WHERE MatchID=@MatchID;

#Comprobar qué jugadores se han caído de la partida y sus estadísticas de kills-muertes no coinciden
SELECT * FROM playerstats a, (SELECT b.MatchID,b.Player,SUM(b.Kills) AS PSumKills from weaponkillsbyplayer b GROUP BY b.Player) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Kills<>x.PSumKills
SELECT * FROM playerstats a, (SELECT b.MatchID,b.Player,SUM(b.Deaths) AS PSumDeaths from weapondeathsbyplayer b GROUP BY b.Player) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Deaths<>x.PSumDeaths
SELECT * FROM playerstats a, (SELECT b.MatchID,b.killer AS Player,SUM(b.Kills) AS PSumKills from killsbyplayer b GROUP BY b.Killer) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Kills<>x.PSumKills
SELECT * FROM playerstats a, (SELECT b.MatchID,b.killer AS Player,SUM(b.Deaths) AS PSumDeaths from deathsbyplayer b GROUP BY b.Killer) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Kills<>x.PSumDeaths
SELECT * FROM playerstats a, (SELECT b.MatchID,b.Victim AS Player,SUM(b.Kills) AS PSumKills from killsbyplayer b GROUP BY b.Victim) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Deaths<>x.PSumKills
SELECT * FROM playerstats a, (SELECT b.MatchID,b.Victim AS Player,SUM(b.Deaths) AS PSumDeaths from deathsbyplayer b GROUP BY b.Victim) x where a.MatchID=x.MatchID AND a.Player=x.Player AND a.Deaths<>x.PSumDeaths

SET @MatchID=10;
SELECT a.*, b.K,c.K,d.K,e.D
FROM playerstats a, (SELECT SUM(x1.kills) AS K,x1.Killer AS player,x1.MatchID FROM killsbyplayer x1 GROUP BY x1.Killer,x1.MatchID) b, (SELECT SUM(x2.Deaths) AS K,x2.Killer AS Player,x2.MatchID FROM deathsbyplayer x2 GROUP BY x2.Killer,x2.MatchID) c, (SELECT SUM(x3.Kills) AS K,x3.Player,x3.MatchID FROM weaponkillsbyplayer x3 GROUP BY x3.Player,x3.MatchID) d, (SELECT SUM(x4.Deaths) AS D,x4.Player,x4.MatchID FROM weapondeathsbyplayer x4 GROUP BY x4.Player,x4.MatchID) e
WHERE a.Player=b.player AND a.Player=c.player AND a.Player=d.Player AND a.Player=e.Player AND a.MatchID=b.MatchID AND a.MatchID=c.MatchID AND a.MatchID=d.MatchID AND a.MatchID=e.MatchID
AND a.MatchID=@MatchID
AND (a.Kills<>b.K OR a.Kills<>c.K OR a.Kills<>d.K OR a.Deaths<>e.D)

#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID=0;

#Mismo SteamID y distinto nick ingame
SELECT  distinct a.SteamID,a.Player,a.MatchID,b.Player,b.MatchID
FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player AND a.SteamID>0 AND a.Player NOT LIKE 'Streamer%' AND a.Player NOT LIKE '[BST2]%' AND b.Player NOT LIKE 'Streamer%' AND b.Player NOT LIKE '[BST2]%'
ORDER BY a.SteamID