-- ### MISC DATA SCRIPTS FOR HLL DATAWAREHOUSE (PostgreSQL version)

CREATE SCHEMA IF NOT EXISTS hlldw;

SELECT * FROM playerstats WHERE ShortestLifeSec<0;
SELECT count(*) FROM gamematch;
SELECT count(*) FROM playerstats;
SELECT count(*) FROM killsbyplayer;

SELECT * FROM playerstats WHERE player LIKE 'César';

SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname = 'hlldw' ORDER BY tablename,indexname;


SET @MatchID=1;

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
WHERE a.MatchID=1 AND (a.Kills<>KillsInKillsByPlayer OR a.Kills<>KillsIndeathsbyplayer OR a.Kills<>KillsInweaponkillsbyplayer OR a.Deaths<>DeathsInweapondeathsbyplayer OR a.Deaths<>DeathsInKillsByPlayer OR a.Deaths<>DeathsInDeathsByPlayer)


SELECT a.* FROM playernicks a, (SELECT SteamID FROM playernicks GROUP BY steamid HAVING count(*)>1) AS b WHERE a.SteamID=b.SteamID ORDER BY a.SteamID
SELECT SteamID,count(*) AS NumNicksDistintos FROM playernicks GROUP BY steamid HAVING count(*)>1

SELECT max(combatpoints) FROM playerstats

SELECT  
		'1.123456789123456789'::real AS "real",
		'1.123456789123456789'::float AS "Float",
        '1.123456789123456789'::double PRECISION AS "double precision",
        '1.123456789123456789'::float(1) AS "float(1)",
        '1.123456789123456789'::float(2) AS "float(4)",
        '1.123456789123456789'::float(2) AS "float(8)",
        '1.123456789123456789'::float(24) AS "float(24)",
        '1.123456789123456789'::float(48) AS "float(25)",
        '1.123456789123456789'::float(48) AS "float(53)";
        
SELECT max(kd),max(killsmin),max(deathsmin) FROM playerstats;

SELECT  
		'1.123456789123456789'::float4,
		'1.123456789123456789'::float8;

SELECT 1::BIT(1),0::BIT(1);

SELECT '1'::BIT(1);

SELECT * FROM playernicks WHERE mainnick2=TRUE LIMIT 10;
UPDATE playernicks SET mainnick=b'1' WHERE mainnick2=TRUE;

SELECT * FROM matchsquads LIMIT 10;

SELECT count(*) FROM hlldw.matchsquads
SELECT count(*) FROM hlldw.matchsquads_old
SELECT max(RCONMAtchID) FROM gamematch

SELECT * FROM gamematch LIMIT 10;

CREATE TABLE IF NOT EXISTS GameMatch_bak (
  MatchID BIGINT NOT NULL,
  CMID INT NOT NULL,
  RCONMatchID BIGINT NOT NULL,
  MatchName VARCHAR(50) NOT NULL,
  MatchDesc VARCHAR(150) NOT NULL,
  ClansCoAllies VARCHAR(50) NOT NULL,
  ClansCoAxis VARCHAR(50) NOT NULL,
  StartTime timestamptz NOT NULL,
  EndTime timestamptz NOT NULL,
  DurationSec INT NOT NULL,
  RCONMapName VARCHAR(50) NOT NULL,
  RCONServerNumber VARCHAR(5) NOT NULL,
  StatsUrl VARCHAR(2048) NOT NULL,
  JSONStatsURL VARCHAR(2048) NOT NULL,
  GameServerName VARCHAR(255) NOT NULL,
  GameServerIP VARCHAR(15) NOT NULL,
  GameServerOwner VARCHAR(100) NOT NULL,
  MapID SMALLINT NOT NULL,
  ResultAllies SMALLINT NULL,
  ResultAxis SMALLINT NOT NULL,
  MatchType SMALLINT NOT NULL,
  CompetitionID INT NOT NULL DEFAULT '0'::int  
);
CREATE INDEX ix_gamematch_bak_competitionid ON gamematch_bak USING btree (competitionid);
CREATE INDEX ix_gamematch_bak_mapid ON gamematch_bak USING btree (mapid);
--ix_gamematch_sqlInsertMatch original carga pg_load fue BTREE

SELECT * FROM gamematch LIMIT 10;
SELECT count(*) FROM gamematch_bak;
SELECT count(*) FROM gamematch;

ALTER TABLE GameMatch
  ADD COLUMN CompetitionID INT NOT NULL DEFAULT '0'::int;

ALTER TABLE gamematch add CONSTRAINT fkgamematch_mapid FOREIGN KEY (mapid) REFERENCES map(mapid) ON DELETE RESTRICT ON UPDATE RESTRICT;
 
CREATE INDEX ix_gamematch_competitionid2 ON gamematch USING btree (competitionid);
CREATE INDEX ix_gamematch_mapid ON gamematch USING btree (mapid);


UPDATE gamematch AS a SET MapID=b.MapID, ResultAllies=b.ResultAllies, ResultAxis=b.ResultAxis,MatchType=b.MatchType FROM gamematch_bak as b WHERE a.matchid=b.matchid
UPDATE gamematch AS a SET CompetitionID=b.CompetitionID FROM gamematch_bak as b WHERE a.matchid=b.matchid

SELECT if((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),1,0) AS CheckNumPlayers;

SELECT COUNT(Distinct SteamID) FROM player; >> 188522
EXPLAIN SELECT COUNT(DISTINCT SteamID) FROM playerstats; 188522
SELECT count(*) FROM player;
SELECT count(*) FROM (SELECT count(*) FROM playerstats GROUP BY SteamID) a;

SELECT CASE	WHEN (SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats) THEN 1	ELSE 0 END

SELECT max(MATCHID),max(RCONMatchID) FROM gamematch
SELECT * FROM gamematch WHERE matchID=26555
SELECT * FROM gamematch WHERE RCONmatchID=1527904

SELECT * FROM MAP WHERE mapkey='hill400_offensive_us'
SELECT count(*) FROM gamematch
