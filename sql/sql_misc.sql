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
 
 
SELECT COLLATION_NAME, PAD_ATTRIBUTE FROM INFORMATION_SCHEMA.COLLATIONS WHERE CHARACTER_SET_NAME = 'utf8mb4';
SELECT * FROM INFORMATION_SCHEMA.COLLATIONS WHERE CHARACTER_SET_NAME = 'utf8mb4';
SELECT * FROM INFORMATION_SCHEMA.COLLATIONS WHERE COLLATION_NAME LIKE 'uca%';
SELECT * FROM INFORMATION_SCHEMA.COLLATIONS WHERE COLLATION_NAME LIKE '%span%';
SELECT * FROM INFORMATION_SCHEMA.COLLATIONS WHERE id=2311

SHOW SESSION VARIABLES LIKE 'character\_set\_%';
SHOW SESSION VARIABLES LIKE 'collation\_%';
SET collation_connection = @@collation_database;
SET collation_connection = "utf8mb4_unicode_ci";
SET collation_connection = uca1400_as_cs;
SET collation_connection = uca1400_ai_ci;
SET NAMES utf8mb4 COLLATE uca1400_as_cs; 

SELECT @@collation_database;

SELECT @@collation_database;
ALTER DATABASE hlldw DEFAULT COLLATE ='uca1400_as_cs';

ALTER TABLE clan CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE clan MODIFY ClanName VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE clan MODIFY Country VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE clan MODIFY ClanAcro VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from clan;

ALTER TABLE clantag CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE clantag MODIFY ClanTag VARCHAR(15) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from clantag;

ALTER TABLE community CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE community MODIFY CommunityName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from community;

ALTER TABLE competition CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE competition MODIFY CompetitionName VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE competition MODIFY CompetitionOrga VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from competition;

ALTER TABLE deathsbyplayer CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE deathsbyplayer MODIFY Victim VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE deathsbyplayer MODIFY Killer VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from deathsbyplayer;

ALTER TABLE gamematch CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY MatchName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY MatchDesc VARCHAR(150) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY ClansCoAllies VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY ClansCoAxis VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY RCONMapName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY RCONServerNumber VARCHAR(5) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY StatsUrl VARCHAR(2048) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY JSONStatsURL VARCHAR(2048) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY GameServerName VARCHAR(255) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY GameServerIP VARCHAR(15) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE gamematch MODIFY GameServerOwner VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from gamematch;

ALTER TABLE killsbyplayer CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE killsbyplayer MODIFY Victim VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE killsbyplayer MODIFY Killer VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from killsbyplayer;

ALTER TABLE map CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE map MODIFY MapName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE map MODIFY MapKey VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE map MODIFY MapDesc VARCHAR(100) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from map;

ALTER TABLE matchsquads CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchsquads MODIFY Player VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchsquads MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchsquads MODIFY SquadRole VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchsquads MODIFY PlayerRole VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchsquads MODIFY SquadName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from matchsquads;

ALTER TABLE matchstreamers CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchstreamers MODIFY CastURL VARCHAR(2048) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchstreamers MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from matchstreamers;

ALTER TABLE matchtype CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE matchtype MODIFY MatchTypeDesc VARCHAR(45) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from matchtype;

ALTER TABLE player CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE player MODIFY DWPlayerID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE player MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from player;

SET GLOBAL foreign_key_checks=OFF;
SET GLOBAL foreign_key_checks=ON;
SHOW GLOBAL VARIABLES LIKE 'foreign_key_checks';
ALTER TABLE playerstats drop CONSTRAINT `fkPlayerStats_DWPlayerID`
ALTER TABLE playerstats CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY Player VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY DWPlayerID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY Nemesis MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY Victims MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY PlayerClanTag VARCHAR(15) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY KillsByWeapons MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats MODIFY DeathsByWeapons MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerstats ADD CONSTRAINT `fkPlayerStats_DWPlayerID` FOREIGN KEY (`DWPlayerID`) REFERENCES `player` (`DWPlayerID`) ON DELETE NO ACTION ON UPDATE NO ACTION;
show full columns from playerstats;

ALTER TABLE player CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE player MODIFY DWPlayerID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE player MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from player;

ALTER TABLE playerhits CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerhits MODIFY Player VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerhits MODIFY Victim VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerhits MODIFY Weapon VARCHAR(500) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playerhits MODIFY Type VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from playerhits;

ALTER TABLE playernicks CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playernicks MODIFY SteamID VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE playernicks MODIFY PlayerNick VARCHAR(30) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from playernicks;

ALTER TABLE weapon CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Weapon VARCHAR(500) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Category1 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Category2 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Category3 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Side1 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Side2 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY Model VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapon MODIFY WeaponFull VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from weapon;

ALTER TABLE weapondeathsbyplayer CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapondeathsbyplayer MODIFY Player VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weapondeathsbyplayer MODIFY Weapon VARCHAR(500) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from weapondeathsbyplayer;

ALTER TABLE weaponkillsbyplayer CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weaponkillsbyplayer MODIFY Player VARCHAR(50) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
ALTER TABLE weaponkillsbyplayer MODIFY Weapon VARCHAR(500) CHARACTER SET utf8mb4 COLLATE uca1400_as_cs;
show full columns from weaponkillsbyplayer;

SELECT * FROM INFORMATION_SCHEMA.COLLATION_CHARACTER_SET_APPLICABILITY WHERE COLLATION_NAME LIKE 'uca1400_ai_ci';

UPDATE INFORMATION_SCHEMA.COLLATIONS SET CHARACTER_SET_NAME = 'utf8mb4',ID=2311 WHERE COLLATION_NAME='uca1400_as_cs';

CREATE TABLE prueba (campo varchar(20) PRIMARY KEY);
INSERT INTO prueba (campo) VALUES ('á');
SELECT * FROM prueba;
DROP TABLE prueba;

call proc_InsertPlayerStats (1,'INSERT INTO PlayerStats (CMID,MatchID,Player,        DWPlayerID,RCONPlayerID,SteamID,        Kills,Deaths,TKs,        KD,MaxKillStreak,KillsMin,DeathsMin,        MaxDeathStreak,MaxTKStreak,DeathByTK,DeathByTKStreak,        LongestLifeSec,ShortestLifeSec,MatchActiveTimeSec,        Nemesis,Victims,KillsByWeapons,DeathsByWeapons,        CombatPoints,OffensePoints,DefensePoints,SupportPoints)        VALUES (1,1635,\'alaska.30\',            \'76561199526856801\',265401,\'76561199526856801\',            0,1,0,            0.0,0,0.0,0.16,            1,0,0,0,            335,335,379,            \'{\\"miwel27[250H]\\": 1}\',\'{}\',\'{}\',\'\\"\\"\',            0,0,0,0)')

call proc_InsertPlayerStats (1,'show databases;');

SELECT * FROM hll_log

SET NAMES utf8mb4 COLLATE uca1400_as_cs;

SELECT 1 from gamematch where CMID=1 AND RCONMatchID=1524577
SELECT * FROM gamematch WHERE MatchID=1642

SELECT * FROM playerstats WHERE MatchID=1643

SELECT * FROM killsbyplayer WHERE killer='César'

SELECT DISTINCT weapon FROM weaponkillsbyplayer WHERE weapon NOT IN (SELECT weapon FROM weapon)
SELECT DISTINCT weapon FROM weapondeathsbyplayer WHERE weapon NOT IN (SELECT weapon FROM weapon)
SELECT DISTINCT weapon FROM weapon WHERE weapon NOT IN (SELECT DISTINCT weapon FROM weaponkillsbyplayer)
SELECT DISTINCT weapon FROM weapon WHERE weapon NOT IN (SELECT DISTINCT weapon FROM weapondeathsbyplayer)

SELECT DISTINCT Weapon collate utf8mb4_unicode_ci FROM weaponkillsbyplayer a WHERE a.matchID=1 AND a.weapon IN (SELECT DISTINCT weapon collate utf8mb4_unicode_ci FROM weapon);

SELECT count(*) FROM gamematch WHERE RCONMatchID in
(1524577,1524586,1524598,1524608,1524614,1524622,1524624,1524627,1524630,1524632,1524637,1524643,1524698,1524699,1524702,1524727,1524742,1524768,1524769,1524793,1524835,1524838,1524851,1524856,1524865,1524872,1524874,1524875,1524880,1524889,1524911,1524919,1524923,1524934,1524935,1524939,1524954,1524974,1524980,1525013,1525037,1525069,1525071,1525073,1525103,1525118,1525120,1525168,1525185,1525204,1525206,1525213,1525236,1525248,1525249)

SELECT * FROM gamematch WHERE endtime>='2023-10-15 00:00:00.000'

SELECT * FROM gamematch WHERE rconmatchid=1526073

2023-12-09 12:07:01,916 ERROR root Error in HLL_DW_DBLoad.py sqlInsertMatch 1 || args: ('mapID not found in table map for mapkey=hill400_offensive_us or several results found',) || ErrDesc: <class 'Exception'> ||ErrMsg: Error searching mapID from MapKey in SQL sentence >> (( SELECT mapID from map where MapKey='hill400_offensive_us' )) for array (( {'RCONMatchID': '1526504', 'CreationTime': '2023-10-30T01:35:30.864', 'StartTime': '2023-10-29T22:29:39', 'EndTime': '2023-10-30T01:27:45', 'DurationSec': 10686, 'RCONServerNumber': '2', 'RCONMapName': 'hill400_offensive_us'} ))