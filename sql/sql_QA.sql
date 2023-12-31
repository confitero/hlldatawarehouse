-- ### FIX DATA SCRIPTS FOR HLL DATAWAREHOUSE

#FILL field playerstats.PlayerTag and playerstats.ClanID from embed TAG in player nick RCON json stats
###UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0


#COMPROBAR QUE TODOS COINCIDEN (sumatorio de kills y death de la partida deben coincidir, salvo caídas de jugadores o cambios de nick entre caídas)
USE hlldw;
SET @MatchID=1;
SELECT * FROM gamematch WHERE MatchID=@MatchID;

SELECT if((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),"Error: player count and playerstats distinct steamID not equal","OK") AS CheckNumPlayers;
SELECT CASE (SELECT COUNT(Distinct SteamID) FROM player) WHEN (SELECT COUNT(DISTINCT SteamID) FROM playerstats) THEN 'OK, playerstats equals player' ELSE 'Error: player count and playerstats distinct steamID not equal' END AS CheckNumPlayers;
SELECT CASE (SELECT COUNT(*) FROM player) WHEN (SELECT COUNT(*) FROM (SELECT 1 FROM playerstats GROUP BY SteamID) AS a) THEN 'OK, playerstats equals player' ELSE 'Error: player count and playerstats distinct steamID not equal' END AS CheckNumPlayers;


#Las siguientes consultas deben devolver todas 0
SELECT 'DiffKill_Deaths',if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID)<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID),1,0)
UNION all
SELECT 'DiffKill_Kills',if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID)<>(SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID),1,0)
UNION all
SELECT 'DiffKill_Deaths',if((SELECT SUM(Kills) FROM playerstats WHERE MatchID=@MatchID)<>(SELECT SUM(deaths) FROM playerstats WHERE MatchID=@MatchID),1,0)
UNION all
SELECT 'DiffKill_Deaths',if((SELECT SUM(Kills) FROM playerstats WHERE MatchID=@MatchID)<>(SELECT SUM(kills) FROM killsbyplayer WHERE MatchID=@MatchID),1,0)

#Verificar que coinciden las kills y deaths de las diferentes tablas
SELECT COUNT(*),'NumPlayers' FROM playerstats WHERE MatchID=@MatchID
UNION all
SELECT SUM(kills),'killsbyplayer.Kills' FROM killsbyplayer WHERE MatchID=@MatchID
UNION all
SELECT SUM(deaths),'deathsbyplayer.Deaths' FROM deathsbyplayer WHERE MatchID=@MatchID
UNION all
SELECT SUM(kills),'weaponkillsbyplayer.kills' FROM weaponkillsbyplayer WHERE MatchID=@MatchID
UNION all
SELECT SUM(Deaths),'weapondeathsbyplayer.deaths' FROM weapondeathsbyplayer WHERE MatchID=@MatchID
UNION all
SELECT SUM(kills),'playerstats.kills' FROM playerstats WHERE MatchID=@MatchID
UNION all
SELECT SUM(deaths),'playerstats.deaths' FROM playerstats WHERE MatchID=@MatchID;

#Comprobar que no hay incoherencia entre players en las tablas de una partida
#Todas las consultas deben devolver 0
SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=@MatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=@MatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID=@MatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID=@MatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM weaponkillsbyplayer WHERE matchID=@MatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM weapondeathsbyplayer WHERE matchID=@MatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=@MatchID AND kills>0 AND player NOT IN (SELECT player FROM killsbyplayer WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=@MatchID AND Deaths>0 AND player NOT IN (SELECT player FROM deathsbyplayer WHERE matchID=@MatchID)
UNION all
SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=@MatchID AND kills>0 AND player NOT IN (SELECT player FROM weaponkillsbyplayer WHERE matchID=@MatchID);


#Comprobar para qué jugadores sus estadísticas de kills-muertes no coinciden
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
WHERE a.MatchID=@MatchID AND (a.Kills<>KillsInKillsByPlayer OR a.Kills<>KillsIndeathsbyplayer OR a.Kills<>KillsInweaponkillsbyplayer OR a.Deaths<>DeathsInweapondeathsbyplayer OR a.Deaths<>DeathsInKillsByPlayer OR a.Deaths<>DeathsInDeathsByPlayer)


#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID='0';
SELECT * FROM playerstats a WHERE a.SteamID IS NULL;

#Jugadores sin bando que tengan kills o muertes de las que poder sacar el bando
SELECT * FROM playerstats a WHERE a.kills+a.Deaths>0 AND (a.PlayerSide is null OR a.PlayerSide NOT IN (0,1,2)) AND MatchID=@MatchID;

#Variaciones de nicks de jugadores
SELECT  distinct a.SteamID,a.Player FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player ORDER BY a.SteamID
SELECT  distinct a.SteamID,a.Player FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<b.Player ORDER BY a.SteamID