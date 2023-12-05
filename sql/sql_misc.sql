-- ### FIX DATA SCRIPTS FOR HLL DATAWAREHOUSE

#FILL field playerstats.PlayerTag and playerstats.ClanID from embed TAG in player nick RCON json stats
UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0


#COMPROBAR QUE TODOS COINCIDEN (sumatorio de kills y death de la partida deben coincidir, salvo caídas de jugadores o cambios de nick entre caídas)
SET @MatchID=4;
SELECT if((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),"Error: player count and playerstats distinct steamID not equal","") AS CheckNumPlayers;
SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID)<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID),1,0) AS DiffKill_Deaths;
SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=@MatchID)<>(SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID),1,0) AS DiffKill_Kills;
SELECT if((SELECT SUM(Kills) FROM playerstats WHERE MatchID=@MatchID)<>(SELECT SUM(deaths) FROM playerstats WHERE MatchID=@MatchID),1,0) AS DiffKill_Deaths;
SELECT if((SELECT SUM(Kills) FROM playerstats WHERE MatchID=@MatchID)<>(SELECT SUM(kills) FROM killsbyplayer WHERE MatchID=@MatchID),1,0) AS DiffKill_Deaths;


SELECT COUNT(*) FROM playerstats WHERE MatchID=@MatchID;
SELECT SUM(kills) FROM killsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(Deaths) FROM weapondeathsbyplayer WHERE MatchID=@MatchID;
SELECT SUM(kills) FROM playerstats WHERE MatchID=@MatchID;
SELECT SUM(deaths) FROM playerstats WHERE MatchID=@MatchID;

#Comprobar que no hay incoherencia entre players en las tablas de una partida
SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=@MatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=@MatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID=@MatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID=@MatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM weaponkillsbyplayer WHERE matchID=@MatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM weapondeathsbyplayer WHERE matchID=@MatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=@MatchID AND kills>0 AND player NOT IN (SELECT player FROM killsbyplayer WHERE matchID=@MatchID);
SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=@MatchID AND Deaths>0 AND player NOT IN (SELECT player FROM deathsbyplayer WHERE matchID=@MatchID);
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
WHERE a.MatchID=@MatchID AND (a.Kills<>KillsInKillsByPlayer OR a.Kills<>KillsIndeathsbyplayer OR a.Kills<>KillsInweaponkillsbyplayer OR a.Deaths<>DeathsInweapondeathsbyplayer)


#Jugadores sin SteamID
SELECT * FROM playerstats a WHERE a.SteamID=0;

#Jugadores sin bando
SELECT * FROM playerstats a WHERE (a.PlayerSide is null OR a.PlayerSide NOT IN (0,1,2)) AND MatchID=@MatchID;

#Variaciones de nicks de jugadores
SELECT  distinct a.SteamID,a.Player FROM playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player ORDER BY a.SteamID


UPDATE playerstats a, gamematch b, deathsbyplayer c,playerstats d SET a.PlayerSide=1+(d.PlayerSide MOD 2)
WHERE a.Deaths>0 AND a.PlayerSide=0 AND a.MatchID=605 AND a.MatchID=b.MatchID AND a.MatchID=c.MatchID AND a.Player=c.Victim AND a.MatchID=d.MatchID AND c.Killer=d.Player AND d.PlayerSide<>0 and c.Deaths=(SELECT max(c.Deaths) FROM deathsbyplayer x, PlayerStats y WHERE a.Player=x.Victim AND a.MatchID=x.MatchID AND x.MatchID=y.MatchID AND x.Killer=y.Player AND y.PlayerSide<>0);

SELECT * FROM playerstats WHERE DWPlayerID='76561198188795134' AND MatchID=607
SELECT * FROM playerstats WHERE Player='Cabo Ratatula' AND MatchID=605
SELECT * FROM playerstats WHERE Deaths=0 AND Kills=0 AND MatchID=607

SELECT 1+(3 MOD 2)
SELECT 1 FROM DUAL WHERE NOT(1=NULL)
SELECT 1 FROM DUAL WHERE 1=NULL
SELECT 1 FROM DUAL WHERE 1<>NULL
SELECT @@optimizer_switch

# OPTIMIZACIÓN con ÍNDICES
#sqlInsertMatch
EXPLAIN SELECT 1 from gamematch where CMID=1 AND RCONMatchID=1526453
EXPLAIN SELECT matchID from gamematch where CMID=1 AND RCONMatchID=1526453 AND StartTime='2023-10-28 18:02:04.000' AND EndTime='2023-10-28 18:30:21.000'

#sqlCheckNotRegisteredWeapons
EXPLAIN SELECT DISTINCT Weapon FROM weaponkillsbyplayer a WHERE a.matchID=1526453 AND a.weapon NOT IN (SELECT DISTINCT weapon FROM weapon);

#sqlCheckOrInsertPlayer
EXPLAIN SELECT 1 from Player where DWPlayerID='76561199150860232'

#sqlFillPlayerClanAndTAG
EXPLAIN UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0 AND x.MatchID=1;

#sqlFillPlayerMatchSide
EXPLAIN UPDATE playerstats a, weaponkillsbyplayer c, weapon d SET a.PlayerSide=d.Side WHERE a.MatchID=1 AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0 and c.Kills=(SELECT max(x.Kills) FROM weaponkillsbyplayer x, weapon y WHERE a.Player=x.Player AND a.MatchID=x.MatchID AND x.Weapon=y.Weapon AND y.Side<>0); 
EXPLAIN UPDATE playerstats a, weapondeathsbyplayer b, weapon c SET a.PlayerSide = CASE when c.side=1 then 2 when c.side=2 then 1 else 0 end WHERE a.MatchID=1 AND a.PlayerSide IS NULL AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.side<>0 and b.Deaths=(SELECT max(x.deaths) FROM weapondeathsbyplayer x, weapon y WHERE a.Player=x.Player AND a.MatchID=x.MatchID AND x.Weapon=y.Weapon AND y.Side<>0);
EXPLAIN UPDATE playerstats a, deathsbyplayer c, playerstats d SET a.PlayerSide=1+(d.PlayerSide MOD 2) WHERE a.Deaths>0 AND a.PlayerSide is null AND a.MatchID=1 AND a.MatchID=c.MatchID AND a.Player=c.Victim AND a.MatchID=d.MatchID AND c.Killer=d.Player AND d.PlayerSide<>0 AND d.PlayerSide is not NULL and c.Deaths=(SELECT max(c.Deaths) FROM deathsbyplayer x, PlayerStats y WHERE a.Player=x.Victim AND a.MatchID=x.MatchID AND x.MatchID=y.MatchID AND x.Killer=y.Player AND y.PlayerSide<>0);

id|select_type       |table|type|possible_keys                                 |key                   |key_len|ref                       |rows|Extra                   |
--+------------------+-----+----+----------------------------------------------+----------------------+-------+--------------------------+----+------------------------+
 1|PRIMARY           |c    |ref |fkDeaths_GameMatch_idx                        |fkDeaths_GameMatch_idx|4      |const                     |448 |                        |
 1|PRIMARY           |a    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1|ix_PlayerStats_1      |208    |const,hlldw.c.Victim,const|1   |Using where             |
 1|PRIMARY           |d    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1|ix_PlayerStats_1      |206    |const,hlldw.c.Killer      |1   |Using where; Using index|
 2|DEPENDENT SUBQUERY|y    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1|ix_PlayerStats_1      |4      |hlldw.a.MatchID           |1   |Using where; Using index|
 2|DEPENDENT SUBQUERY|x    |ref |fkDeaths_GameMatch_idx                        |fkDeaths_GameMatch_idx|4      |hlldw.a.MatchID           |313 |Using where             |
 
 id|select_type       |table|type|possible_keys                                                  |key                                     |key_len|ref                                          |rows|Extra                   |
--+------------------+-----+----+---------------------------------------------------------------+----------------------------------------+-------+---------------------------------------------+----+------------------------+
 1|PRIMARY           |a    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1,ix_PlayerStats_2|fkPlayerResults_GameMatch_idx           |4      |const                                        |78  |Using where             |
 1|PRIMARY           |c    |ref |fkDeaths_GameMatch_idx,ix_DeathsByPlayer_sqlFillPlayerMatchSide|ix_DeathsByPlayer_sqlFillPlayerMatchSide|206    |const,hlldw.a.Player                         |1   |Using where; Using index|
 1|PRIMARY           |d    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1,ix_PlayerStats_2|ix_PlayerStats_1                        |206    |const,hlldw.c.Killer                         |1   |Using where; Using index|
 2|DEPENDENT SUBQUERY|y    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1,ix_PlayerStats_2|ix_PlayerStats_1                        |4      |hlldw.a.MatchID                              |1   |Using where; Using index|
 2|DEPENDENT SUBQUERY|x    |ref |fkDeaths_GameMatch_idx,ix_DeathsByPlayer_sqlFillPlayerMatchSide|ix_DeathsByPlayer_sqlFillPlayerMatchSide|408    |hlldw.a.MatchID,hlldw.a.Player,hlldw.y.Player|1   |Using where; Using index|
 
#sqlFillMatchRolesAux 
EXPLAIN INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side) SELECT DISTINCT 1,a.player,a.SteamID,'Armored','Tank-crew',c.category1,a.PlayerSide FROM
	playerstats a, weaponkillsbyplayer b, weapon c WHERE
	a.MatchID=1 AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1='Tank' AND
	a.Kills>0 AND a.Player IN (SELECT a.Player FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=1 AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND
	c.category1='Tank' GROUP BY a.Player HAVING (SUM(b.Kills)/a.Kills)>=0.20);
	

id|select_type       |table|type  |possible_keys                                                                  |key                                                |key_len|ref           |rows|Extra                       |
--+------------------+-----+------+-------------------------------------------------------------------------------+---------------------------------------------------+-------+--------------+----+----------------------------+
 1|PRIMARY           |a    |ref   |fkPlayerResults_GameMatch_idx,ix_PlayerStats_1                                 |fkPlayerResults_GameMatch_idx                      |4      |const         |78  |Using where; Using temporary|
 1|PRIMARY           |b    |ref   |fkWeapinKills_GameMatch_idx,ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons|ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons|4      |const         |1   |Using where; Using index    |
 1|PRIMARY           |c    |eq_ref|Weapon_UNIQUE                                                                  |Weapon_UNIQUE                                      |2003   |hlldw.b.Weapon|1   |Using where                 |
 2|DEPENDENT SUBQUERY|a    |range |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_1 |ix_PlayerStats_1                                   |4      |              |78  |Using where; Using index    |
 2|DEPENDENT SUBQUERY|b    |ref   |fkWeapinKills_GameMatch_idx,ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons|ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons|4      |const         |1   |Using where; Using index    |
 2|DEPENDENT SUBQUERY|c    |eq_ref|Weapon_UNIQUE                                                                  |Weapon_UNIQUE                                      |2003   |hlldw.b.Weapon|1   |Using where                 |
 
 #sqlFillMatchRolesAux 
EXPLAIN INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
	SELECT DISTINCT 1,a.player,a.SteamID,'Armored','Tank-crew','Tank',a.PlayerSide FROM
	playerstats a  WHERE
	a.MatchID=1 AND a.Player IN (SELECT x.Player FROM playerstats x, weaponkillsbyplayer y, weapon z WHERE x.MatchID=1 AND x.player=y.player AND y.MatchID=1 AND y.Weapon=z.Weapon AND
	z.category1='Tank' GROUP BY x.Player HAVING (SUM(y.Kills)/sum(x.Kills))>=0.20);

1|player              |SteamID          |Armored|Tank-crew|category1|PlayerSide|
-+--------------------+-----------------+-------+---------+---------+----------+
1|-L- [250H] Barba Neg|76561198887897325|Armored|Tank-crew|Tank     |         1|
1|-L- [HFL] Xhien Omur|76561198148883890|Armored|Tank-crew|Tank     |         1|
1|-L-[250H]Ruso       |76561198220519063|Armored|Tank-crew|Tank     |         1|
1|-X- migs            |76561199088937259|Armored|Tank-crew|Tank     |         2|
1|-X-[H9H] Hans       |76561198144421884|Armored|Tank-crew|Tank     |         2|
1|-X-danitofgi        |76561198845849886|Armored|Tank-crew|Tank     |         2|
1|-X-JUPACAROS        |76561198357981636|Armored|Tank-crew|Tank     |         2|

 #sqlFillMatchRolesAux 
EXPLAIN INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
	SELECT 1,x.Player,x.SteamID,'Armored','Tank-crew','Tank',x.PlayerSide FROM playerstats x, weaponkillsbyplayer y, weapon z WHERE x.MatchID=1 AND x.player=y.player AND y.MatchID=1 AND y.Weapon=z.Weapon AND
	z.category1='Tank'
	GROUP BY 1,x.Player,x.SteamID,'Armored','Tank-crew','Tank',x.PlayerSide HAVING (SUM(y.Kills)/sum(x.Kills))>=0.20

#sqlFillMatchRoles
EXPLAIN INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
	SELECT DISTINCT 1,a.player,a.SteamID,'Infantry','Infantry','Infantry',a.PlayerSide FROM playerstats a
	WHERE a.MatchID=1 AND a.Player not IN (SELECT DISTINCT x.Player FROM matchsquads x WHERE x.MatchID=1)
	
id|select_type |table|type|possible_keys                                                  |key                                 |key_len|ref  |rows|Extra                                    |
--+------------+-----+----+---------------------------------------------------------------+------------------------------------+-------+-----+----+-----------------------------------------+
 1|PRIMARY     |a    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1|ix_PlayerStats_2                    |4      |const|78  |Using where; Using index; Using temporary|
 2|MATERIALIZED|x    |ref |fk_MatchSquads_GameMatch_MatchID_idx                           |fk_MatchSquads_GameMatch_MatchID_idx|4      |const|78  |                                         |
 
EXPLAIN INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
	SELECT DISTINCT 1,a.player,a.SteamID,'Infantry','Infantry','Infantry',a.PlayerSide FROM playerstats a
	WHERE a.MatchID=1 AND NOT EXISTS (SELECT 1 FROM matchsquads x WHERE x.MatchID=1 AND x.Player=a.Player)

id|select_type       |table|type|possible_keys                                                  |key                                 |key_len|ref  |rows|Extra                                    |
--+------------------+-----+----+---------------------------------------------------------------+------------------------------------+-------+-----+----+-----------------------------------------+
 1|PRIMARY           |a    |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1|ix_PlayerStats_2                    |4      |const|78  |Using where; Using index; Using temporary|
 2|DEPENDENT SUBQUERY|x    |ref |fk_MatchSquads_GameMatch_MatchID_idx                           |fk_MatchSquads_GameMatch_MatchID_idx|4      |const|78  |Using where                              |
 
 #sqlCheckMatchNumPlayers
EXPLAIN SELECT COUNT(*) AS NumPlayers FROM playerstats WHERE MatchID=1 AND SteamID NOT IN (SELECT DISTINCT SteamID FROM player);

id|select_type |table      |type|possible_keys                                                  |key             |key_len|ref  |rows|Extra                   |
--+------------+-----------+----+---------------------------------------------------------------+----------------+-------+-----+----+------------------------+
 1|PRIMARY     |playerstats|ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1|ix_PlayerStats_2|4      |const|78  |Using where; Using index|
 2|MATERIALIZED|player     |ALL |                                                               |                |       |     |390 |                        |
 
 id|select_type       |table      |type          |possible_keys                                                  |key              |key_len|ref  |rows|Extra                                          |
--+------------------+-----------+--------------+---------------------------------------------------------------+-----------------+-------+-----+----+-----------------------------------------------+
 1|PRIMARY           |playerstats|ref           |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1|ix_PlayerStats_2 |4      |const|78  |Using where; Using index                       |
 2|DEPENDENT SUBQUERY|player     |index_subquery|ix_Player_SteamID                                              |ix_Player_SteamID|122    |func |1   |Using index; Using where; Full scan on NULL key|
 
 EXPLAIN SELECT COUNT(*) AS NumPlayers FROM playerstats WHERE MatchID=1 AND NOT EXISTS (SELECT 1 FROM player WHERE player.SteamID=playerstats.SteamID);
 
id|select_type       |table      |type          |possible_keys                                                  |key              |key_len|ref  |rows|Extra                   |
--+------------------+-----------+--------------+---------------------------------------------------------------+-----------------+-------+-----+----+------------------------+
 1|PRIMARY           |playerstats|ref           |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1|ix_PlayerStats_2 |4      |const|78  |Using where; Using index|
 2|DEPENDENT SUBQUERY|player     |index_subquery|ix_Player_SteamID                                              |ix_Player_SteamID|122    |func |1   |Using index             |
 
# sqlCheckKillsAndDeathsSumConsistency
EXPLAIN SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=1)<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=1),1,0) AS DiffKill_Deaths;
 
id|select_type|table         |type|possible_keys                                                  |key                                     |key_len|ref  |rows|Extra         |
--+-----------+--------------+----+---------------------------------------------------------------+----------------------------------------+-------+-----+----+--------------+
 1|PRIMARY    |              |    |                                                               |                                        |       |     |    |No tables used|
 3|SUBQUERY   |deathsbyplayer|ref |fkDeaths_GameMatch_idx,ix_DeathsByPlayer_sqlFillPlayerMatchSide|ix_DeathsByPlayer_sqlFillPlayerMatchSide|4      |const|448 |Using index   |
 2|SUBQUERY   |killsbyplayer |ref |fkKills_GameMatch_idx                                          |fkKills_GameMatch_idx                   |4      |const|456 |              |
 
EXPLAIN SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=1)<>(SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID=1),1,0) AS DiffKill_Kills;

id|select_type|table              |type|possible_keys                                                                                                                      |key                                                    |key_len|ref  |rows|Extra         |
--+-----------+-------------------+----+-----------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------+-------+-----+----+--------------+
 1|PRIMARY    |                   |    |                                                                                                                                   |                                                       |       |     |    |No tables used|
 3|SUBQUERY   |weaponkillsbyplayer|ref |fkWeapinKills_GameMatch_idx,ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons                                                    |ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons    |4      |const|117 |Using index   |
 2|SUBQUERY   |killsbyplayer      |ref |fkKills_GameMatch_idx,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2|ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2|4      |const|456 |Using index   |
 
EXPLAIN SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=1 AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=1);

id|select_type |table        |type|possible_keys                                                                                                                      |key                          |key_len|ref  |rows|Extra      |
--+------------+-------------+----+-----------------------------------------------------------------------------------------------------------------------------------+-----------------------------+-------+-----+----+-----------+
 1|PRIMARY     |killsbyplayer|ref |fkKills_GameMatch_idx,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2|fkKills_GameMatch_idx        |4      |const|456 |Using where|
 2|MATERIALIZED|playerstats  |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                    |fkPlayerResults_GameMatch_idx|4      |const|78  |Using index|
 
 id|select_type |table        |type|possible_keys                                                                                                                                                                              |key                                                    |key_len|ref  |rows|Extra                   |
--+------------+-------------+----+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------+-------+-----+----+------------------------+
 1|PRIMARY     |killsbyplayer|ref |fkKills_GameMatch_idx,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3|ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3|4      |const|456 |Using where; Using index|
 2|MATERIALIZED|playerstats  |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                                                                            |fkPlayerResults_GameMatch_idx                          |4      |const|78  |Using index             |
 
 EXPLAIN SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=1 AND NOT EXISTS (SELECT 1 FROM playerstats WHERE playerstats.matchID=1 AND playerstats.player=killsbyplayer.killer);
 
id|select_type |table        |type|possible_keys                                                                                                                                                                              |key                                                    |key_len|ref  |rows|Extra                   |
--+------------+-------------+----+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------+-------+-----+----+------------------------+
 1|PRIMARY     |killsbyplayer|ref |fkKills_GameMatch_idx,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3|ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3|4      |const|456 |Using where; Using index|
 2|MATERIALIZED|playerstats  |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                                                                            |fkPlayerResults_GameMatch_idx                          |4      |const|78  |Using index             |
 
 
EXPLAIN SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID=1 AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=1);

id|select_type |table        |type|possible_keys                                                                                                                                                                                                                                      |key                                                    |key_len|ref  |rows|Extra                   |
--+------------+-------------+----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------+-------+-----+----+------------------------+
 1|PRIMARY     |killsbyplayer|ref |fkKills_GameMatch_idx,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3,ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_4|ix_KillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_4|4      |const|456 |Using where; Using index|
 2|MATERIALIZED|playerstats  |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                                                                                                                                    |fkPlayerResults_GameMatch_idx                          |4      |const|78  |Using index             |
 
 
EXPLAIN SELECT COUNT(*) AS HitsNotRegistered FROM weaponkillsbyplayer WHERE matchID=1 AND player NOT IN (SELECT player FROM playerstats WHERE matchID=1);

id|select_type |table              |type|possible_keys                                                                                                                              |key                                                |key_len|ref  |rows|Extra                   |
--+------------+-------------------+----+-------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------+-------+-----+----+------------------------+
 1|PRIMARY     |weaponkillsbyplayer|ref |fkWeapinKills_GameMatch_idx,ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons,ix_WeaponKillsByPlayer_sqlCheckKillsAndDeathsSumConsistency|ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons|4      |const|117 |Using where; Using index|
 2|MATERIALIZED|playerstats        |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                            |fkPlayerResults_GameMatch_idx                      |4      |const|78  |Using index             |
 
id|select_type |table              |type|possible_keys                                                                                                                                                                                            |key                                                          |key_len|ref  |rows|Extra                   |
--+------------+-------------------+----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------+-------+-----+----+------------------------+
 1|PRIMARY     |weaponkillsbyplayer|ref |fkWeapinKills_GameMatch_idx,ix_WeaponKillsByPlayer_sqlCheckNotRegisteredWeapons,ix_WeaponKillsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_WeaponKillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2|ix_WeaponKillsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2|4      |const|117 |Using where; Using index|
 2|MATERIALIZED|playerstats        |ref |PRIMARY,fkPlayerResults_GameMatch_idx,fkPlayer_DWPlayerID_idx,ix_PlayerStats_2,ix_PlayerStats_1                                                                                                          |fkPlayerResults_GameMatch_idx                                |4      |const|78  |Using index             |
 
EXPLAIN SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=1 AND Deaths>0 AND player NOT IN (SELECT player FROM deathsbyplayer WHERE matchID=1);

id|select_type       |table         |type|possible_keys                                                                                                                                                                                                                                                  |key                   |key_len|ref  |rows|Extra                   |
--+------------------+--------------+----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------+-------+-----+----+------------------------+
 1|PRIMARY           |playerstats   |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1                                                                                                                                                                                                |ix_PlayerStats_1      |4      |const|78  |Using where; Using index|
 2|DEPENDENT SUBQUERY|deathsbyplayer|ref |fkDeaths_GameMatch_idx,ix_DeathsByPlayer_sqlFillPlayerMatchSide,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3,ix_DeathsByPlayer_sqlC|fkDeaths_GameMatch_idx|4      |const|448 |Using index             |
 
 id|select_type       |table         |type|possible_keys                                                                                                                                                                                                                                                  |key                   |key_len|ref  |rows|Extra                   |
--+------------------+--------------+----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------+-------+-----+----+------------------------+
 1|PRIMARY           |playerstats   |ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1,ix_PlayerStats_3,ix_PlayerStats_4                                                                                                                                                              |ix_PlayerStats_4      |4      |const|78  |Using where; Using index|
 2|DEPENDENT SUBQUERY|deathsbyplayer|ref |fkDeaths_GameMatch_idx,ix_DeathsByPlayer_sqlFillPlayerMatchSide,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency_2,ix_DeathsByPlayer_sqlCheckKillsAndDeathsSumConsistency_3,ix_DeathsByPlayer_sqlC|fkDeaths_GameMatch_idx|4      |const|448 |Using index             |
 
EXPLAIN SELECT count(*) FROM playerstats WHERE SteamID=0 AND matchID=1;

id|select_type|table      |type|possible_keys                                                                                                     |key             |key_len|ref  |rows|Extra                   |
--+-----------+-----------+----+------------------------------------------------------------------------------------------------------------------+----------------+-------+-----+----+------------------------+
 1|SIMPLE     |playerstats|ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1,ix_PlayerStats_3,ix_PlayerStats_4,ix_PlayerStats_5|ix_PlayerStats_5|4      |const|78  |Using where; Using index|

EXPLAIN SELECT count(*) FROM playerstats WHERE SteamID='0' AND matchID=1;
 
id|select_type|table      |type|possible_keys                                                                                                     |key             |key_len|ref        |rows|Extra                   |
--+-----------+-----------+----+------------------------------------------------------------------------------------------------------------------+----------------+-------+-----------+----+------------------------+
 1|SIMPLE     |playerstats|ref |fkPlayerResults_GameMatch_idx,ix_PlayerStats_2,ix_PlayerStats_1,ix_PlayerStats_3,ix_PlayerStats_4,ix_PlayerStats_5|ix_PlayerStats_5|127    |const,const|1   |Using where; Using index|
 
 SHOW INDEX FROM hlldw.playerstats
 SELECT count(*) FROM playerstats
 SELECT count(DISTINCT SteamID) FROM playerstats
 
 
