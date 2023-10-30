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

#COMPROBAR QUE TODOS COINCIDEN (sumatorio de kills y death de la partida deben coincidir, salvo caídas de jugadores o cambios de nick entre caídas)
SET @MatchID=57;
SELECT COUNT(Distinct SteamID) FROM player;
SELECT COUNT(DISTINCT SteamID) FROM playerstats;
SELECT SUM(Kills),SUM(Deaths),SUM(tks),SUM(Kills)+SUM(tks) FROM playerstats WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Deaths) FROM weapondeathsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID;


#Comprobar para qué jugadores sus estadísticas de kills-muertes no coinciden
SET @MatchID=10;
SELECT a.MatchID,a.Player,a.SteamID,a.Kills,a.Deaths,a.TKs,
case when b.KillsInKillsByPlayer IS NULL then 0 ELSE b.KillsInKillsByPlayer END AS KillsInKillsByPlayer,
case when c.KillsIndeathsbyplayer IS NULL then 0 ELSE c.KillsIndeathsbyplayer END AS KillsIndeathsbyplayer,
case when d.KillsInweaponkillsbyplayer IS NULL then 0 ELSE d.KillsInweaponkillsbyplayer END AS KillsInweaponkillsbyplayer,
case when e.DeathsInweapondeathsbyplayer is null then 0 ELSE e.DeathsInweapondeathsbyplayer end AS DeathsInweapondeathsbyplayer,
case when f.DeathsInKillsByPlayer IS NULL then 0 ELSE f.DeathsInKillsByPlayer END AS DeathsInKillsByPlayer,
case when g.DeathsInDeathsByPlayer IS NULL then 0 ELSE g.DeathsInDeathsByPlayer END AS DeathsInDeathsByPlayer
FROM playerstats a LEFT JOIN (SELECT SUM(x1.kills) AS KillsInKillsByPlayer,x1.Killer AS player,x1.MatchID FROM killsbyplayer x1 GROUP BY x1.Killer,x1.MatchID) b ON a.Player=b.player AND a.MatchID=b.MatchID
LEFT JOIN (SELECT SUM(x2.deaths) killsIndeathsbyplayer,x2.Killer AS Player,x2.MatchID FROM deathsbyplayer x2 GROUP BY x2.Killer,x2.MatchID) c ON a.Player=c.player AND a.MatchID=c.MatchID 
LEFT JOIN (SELECT SUM(x3.Kills) AS KillsInweaponkillsbyplayer,x3.Player,x3.MatchID FROM weaponkillsbyplayer x3 GROUP BY x3.Player,x3.MatchID) d ON a.Player=d.Player AND a.MatchID=d.MatchID
LEFT JOIN (SELECT SUM(x4.Deaths) AS DeathsInweapondeathsbyplayer,x4.Player,x4.MatchID FROM weapondeathsbyplayer x4 GROUP BY x4.Player,x4.MatchID) e ON a.Player=e.Player AND a.MatchID=e.MatchID
LEFT JOIN (SELECT SUM(x5.kills) AS DeathsInKillsByPlayer,x5.Victim AS player,x5.MatchID FROM killsbyplayer x5 GROUP BY x5.Victim,x5.MatchID) f ON a.Player=f.player AND a.MatchID=f.MatchID
LEFT JOIN (SELECT SUM(x6.deaths) AS DeathsInDeathsByPlayer,x6.Victim AS player,x6.MatchID FROM deathsbyplayer x6 GROUP BY x6.Victim,x6.MatchID) g ON a.Player=g.player AND a.MatchID=g.MatchID
WHERE a.MatchID=@MatchID AND (not(a.Kills<=>KillsInKillsByPlayer) OR not(a.Kills<=>KillsIndeathsbyplayer) OR not(a.Kills<=>KillsInweaponkillsbyplayer) OR not(a.Deaths<=>DeathsInweapondeathsbyplayer))


#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID=0;

#Mismo SteamID y distinto nick ingame
SELECT  distinct a.SteamID,a.Player,a.MatchID,b.Player,b.MatchID
FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player AND a.SteamID>0 AND a.Player NOT LIKE 'Streamer%' AND a.Player NOT LIKE '[BST2]%' AND b.Player NOT LIKE 'Streamer%' AND b.Player NOT LIKE '[BST2]%'
ORDER BY a.SteamID