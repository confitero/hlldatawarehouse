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
SET @MatchID=5;
SELECT COUNT(Distinct SteamID) FROM player;
SELECT COUNT(DISTINCT SteamID) FROM playerstats;
SELECT SUM(Kills),SUM(Deaths),SUM(tks),SUM(Kills)+SUM(tks) FROM playerstats WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Deaths) FROM weapondeathsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID;

#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID=0;

#Mismo SteamID y distinto nick ingame
SELECT  distinct a.SteamID,a.Player,a.MatchID,b.Player,b.MatchID
FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player AND a.SteamID>0 AND a.Player NOT LIKE 'Streamer%' AND a.Player NOT LIKE '[BST2]%' AND b.Player NOT LIKE 'Streamer%' AND b.Player NOT LIKE '[BST2]%'
ORDER BY a.SteamID