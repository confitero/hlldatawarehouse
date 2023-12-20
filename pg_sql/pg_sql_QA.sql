-- ### FIX DATA SCRIPTS FOR HLL DATAWAREHOUSE (PG Version)

--#FILL field playerstats.PlayerTag and playerstats.ClanID from embed TAG in player nick RCON json stats
--###UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0


--#COMPROBAR QUE TODOS COINCIDEN (sumatorio de kills y death de la partida deben coincidir, salvo caídas de jugadores o cambios de nick entre caídas)
SET session my.MatchID = 26479;
SELECT * FROM gamematch WHERE MatchID=current_setting('my.MatchID')::int;

--SELECT IIF((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),'Error: player count and playerstats distinct steamID not equal'::text,(SELECT COUNT(Distinct SteamID) FROM player)::text) AS CheckNumPlayers;
--SELECT CASE (SELECT COUNT(Distinct SteamID) FROM player) WHEN (SELECT COUNT(DISTINCT SteamID) FROM playerstats) THEN 'OK, playerstats equals player' ELSE 'Error: player count and playerstats distinct steamID not equal' END AS CheckNumPlayers;
SELECT CASE (SELECT COUNT(*) FROM player) WHEN (SELECT COUNT(*) FROM (SELECT 1 FROM playerstats GROUP BY SteamID) AS a) THEN 'OK, playerstats equals player' ELSE 'Error: player count and playerstats distinct steamID not equal' END AS CheckNumPlayers;

--#Las siguientes consultas deben devolver todas 0
SELECT 'DiffKill_Deaths',IIF((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=current_setting('my.MatchID')::int)<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=current_setting('my.MatchID')::int),1,0)
UNION all
SELECT 'DiffKill_Kills',IIF((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=current_setting('my.MatchID')::int)<>(SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID=current_setting('my.MatchID')::int),1,0)
UNION all
SELECT 'DiffKill_Deaths',IIF((SELECT SUM(Kills) FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int)<>(SELECT SUM(deaths) FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int),1,0)
UNION all
SELECT 'DiffKill_Deaths',IIF((SELECT SUM(Kills) FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int)<>(SELECT SUM(kills) FROM killsbyplayer WHERE MatchID=current_setting('my.MatchID')::int),1,0)

--#Verificar que coinciden las kills y deaths de las diferentes tablas
SELECT COUNT(*),'NumPlayers' FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(kills),'killsbyplayer.Kills' FROM killsbyplayer WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(deaths),'deathsbyplayer.Deaths' FROM deathsbyplayer WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(kills),'weaponkillsbyplayer.kills' FROM weaponkillsbyplayer WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(Deaths),'weapondeathsbyplayer.deaths' FROM weapondeathsbyplayer WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(kills),'playerstats.kills' FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int
UNION all
SELECT SUM(deaths),'playerstats.deaths' FROM playerstats WHERE MatchID=current_setting('my.MatchID')::int;

--#Comprobar que no hay incoherencia entre players en las tablas de una partida
--#Todas las consultas deben devolver 0
SELECT COUNT(*) AS HitsNotRegistered,'killsbyplayer.killer no en playerstats.player' AS Comp FROM killsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'killsbyplayer.victim no en playerstats.player' FROM killsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'deathsbyplayer.killer no en playerstats.player' FROM deathsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'deathsbyplayer.victim no en playerstats.player' FROM deathsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'weaponkillsbyplayer.player no en playerstats.player' FROM weaponkillsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND player NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'weapondeathsbyplayer.player no en playerstats.player' FROM weapondeathsbyplayer WHERE matchID=current_setting('my.MatchID')::int AND player NOT IN (SELECT player FROM playerstats WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'playerstats.player no en killsbyplayer.player' FROM playerstats WHERE matchID=current_setting('my.MatchID')::int AND kills>0 AND player NOT IN (SELECT player FROM killsbyplayer WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'playerstats.player no en deathsbyplayer.player' FROM playerstats WHERE matchID=current_setting('my.MatchID')::int AND Deaths>0 AND player NOT IN (SELECT player FROM deathsbyplayer WHERE matchID=current_setting('my.MatchID')::int)
UNION all
SELECT COUNT(*) AS HitsNotRegistered,'playerstats.player no en weaponkillsbyplayer.player' FROM playerstats WHERE matchID=current_setting('my.MatchID')::int AND kills>0 AND player NOT IN (SELECT player FROM weaponkillsbyplayer WHERE matchID=current_setting('my.MatchID')::int);


--#Comprobar para qué jugadores sus kills no coinciden en todas las tablas
SELECT a.MatchID,a.Player,a.SteamID,a.Kills,a.Deaths,a.TKs,
case when b.KillsInKillsByPlayer IS NULL then 0 ELSE b.KillsInKillsByPlayer END AS KillsInKillsByPlayer,
case when c.KillsIndeathsbyplayer IS NULL then 0 ELSE c.KillsIndeathsbyplayer END AS KillsIndeathsbyplayer,
case when d.KillsInweaponkillsbyplayer IS NULL then 0 ELSE d.KillsInweaponkillsbyplayer END AS KillsInweaponkillsbyplayer
FROM playerstats a LEFT JOIN (SELECT SUM(x1.kills) AS KillsInKillsByPlayer,x1.Killer AS player,x1.MatchID FROM killsbyplayer x1 GROUP BY x1.Killer,x1.MatchID) b ON a.Player=b.player AND a.MatchID=b.MatchID
LEFT JOIN (SELECT SUM(x2.deaths) killsIndeathsbyplayer,x2.Killer AS Player,x2.MatchID FROM deathsbyplayer x2 GROUP BY x2.Killer,x2.MatchID) c ON a.Player=c.player AND a.MatchID=c.MatchID
LEFT JOIN (SELECT SUM(x3.Kills) AS KillsInweaponkillsbyplayer,x3.Player,x3.MatchID FROM weaponkillsbyplayer x3 GROUP BY x3.Player,x3.MatchID) d ON a.Player=d.Player AND a.MatchID=d.MatchID
WHERE a.MatchID=current_setting('my.MatchID')::int AND (a.Kills<>KillsInKillsByPlayer OR a.Kills<>KillsIndeathsbyplayer OR a.Kills<>KillsInweaponkillsbyplayer)


--#Comprobar para qué jugadores sus muertes no coinciden en todas las tablas
SELECT a.MatchID,a.Player,a.SteamID,a.Kills,a.Deaths,a.TKs,
case when e.DeathsInweapondeathsbyplayer is null then 0 ELSE e.DeathsInweapondeathsbyplayer end AS DeathsInweapondeathsbyplayer,
case when f.DeathsInKillsByPlayer IS NULL then 0 ELSE f.DeathsInKillsByPlayer END AS DeathsInKillsByPlayer,
case when g.DeathsInDeathsByPlayer IS NULL then 0 ELSE g.DeathsInDeathsByPlayer END AS DeathsInDeathsByPlayer
FROM playerstats a
LEFT JOIN (SELECT SUM(x4.Deaths) AS DeathsInweapondeathsbyplayer,x4.Player,x4.MatchID FROM weapondeathsbyplayer x4 GROUP BY x4.Player,x4.MatchID) e ON a.Player=e.Player AND a.MatchID=e.MatchID
LEFT JOIN (SELECT SUM(x5.kills) AS DeathsInKillsByPlayer,x5.Victim AS player,x5.MatchID FROM killsbyplayer x5 GROUP BY x5.Victim,x5.MatchID) f ON a.Player=f.player AND a.MatchID=f.MatchID
LEFT JOIN (SELECT SUM(x6.deaths) AS DeathsInDeathsByPlayer,x6.Victim AS player,x6.MatchID FROM deathsbyplayer x6 GROUP BY x6.Victim,x6.MatchID) g ON a.Player=g.player AND a.MatchID=g.MatchID
WHERE a.MatchID=current_setting('my.MatchID')::int AND (a.Deaths<>DeathsInweapondeathsbyplayer OR a.Deaths<>DeathsInKillsByPlayer OR a.Deaths<>DeathsInDeathsByPlayer)


--#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID='0';
SELECT * FROM playerstats a WHERE a.SteamID IS NULL;

--#Jugadores sin bando que tengan kills o muertes de las que poder sacar el bando
SELECT * FROM playerstats a WHERE a.kills+a.Deaths>0 AND (a.PlayerSide is null OR a.PlayerSide NOT IN (0,1,2)) AND MatchID=current_setting('my.MatchID')::int;

--#Variaciones de nicks de jugadores
SELECT distinct a.DWPlayerID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<b.Player;
>>> 20.006 filas
>> 35,243s
SELECT distinct a.SteamID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.SteamID=b.SteamID where a.Player<b.Player;
>>> 20.006 filas
>> 53,704s
SELECT distinct a.DWPlayerID FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<b.Player;
>> 13394, 34,94s

--#Variaciones de nicks de jugadores (consulta más eficiente que el join playerstats-playerstats)
SELECT a.SteamID,count(DISTINCT a.Player) AS NumNicksDistintos FROM playerstats a GROUP BY a.SteamID HAVING count(DISTINCT a.Player)>1 
>>> 13.394 filas, 1,722s
SELECT SteamID,count(*) AS NumNicksDistintos FROM playernicks GROUP BY steamid HAVING count(*)>1;
13.391 filas, 0,045s
SELECT a.DWPlayerID,count(DISTINCT a.Player) AS NumNicksDistintos FROM playerstats a GROUP BY a.DWPlayerID HAVING count(DISTINCT a.Player)>1
>>> 1394 filas, 3,158s

--Nicks concretos distintos para cada SteamID con varios nicks usados
SELECT a.* FROM playernicks a, (SELECT SteamID FROM playernicks GROUP BY steamid HAVING count(*)>1) AS b WHERE a.SteamID=b.SteamID ORDER BY a.SteamID
>>> 33.382 filas

--Jugadores con varios nicks no detectados en playernicks
SELECT x.DWPlayerID FROM (SELECT a.DWPlayerID,count(DISTINCT a.Player) AS NumNicksDistintos FROM playerstats a GROUP BY a.DWPlayerID HAVING count(DISTINCT a.Player)>1) x
WHERE x.DWPlayerID NOT IN (SELECT SteamID FROM playernicks GROUP BY steamid HAVING count(*)>1)

SELECT * FROM playernicks WHERE SteamID='76561198103602938';
SELECT * FROM playernicks WHERE SteamID='76561198156215074';
SELECT * FROM playernicks WHERE SteamID='76561198815297783';

SELECT DISTINCT Player FROM playerstats WHERE SteamID='76561198103602938';
SELECT DISTINCT Player FROM playerstats WHERE SteamID='76561198156215074';
SELECT DISTINCT Player FROM playerstats WHERE SteamID='76561198815297783';


