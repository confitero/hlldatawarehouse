-- ### SQL UTIL SCRIPTS FOR HLL DATAWAREHOUSE: Delete maches by ID, delete all matches, make sql replica, restore sql replica

#Select and execute one SQL util block each time. There are Error break lines between blocks to avoid full script file execution

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

#Delete match by ID

SET @MatchIDList='9,9';
DELETE FROM deathsbyplayer WHERE find_in_set(matchID,@MatchID);
DELETE FROM killsbyplayer WHERE find_in_set(matchID,@MatchID);
DELETE FROM weaponkillsbyplayer WHERE find_in_set(matchID,@MatchID);
DELETE FROM weapondeathsbyplayer WHERE find_in_set(matchID,@MatchID);
DELETE FROM matchsquads WHERE find_in_set(matchID,@MatchID);
DELETE FROM matchstreamers WHERE find_in_set(matchID,@MatchID);
DELETE FROM playerstats WHERE find_in_set(matchID,@MatchID);
SET foreign_key_checks = 0;
delete from player where DWPlayerID not in (select distinct DWPlayerID from playerstats);
delete from playernicks where SteamID not in (select distinct SteamID from playerstats);
SET foreign_key_checks = 1;
delete from gamematch where find_in_set(matchID,@MatchID);

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

#Delete all database matches
SET foreign_key_checks = 0;
TRUNCATE TABLE deathsbyplayer;
TRUNCATE TABLE killsbyplayer;
TRUNCATE TABLE weaponkillsbyplayer;
TRUNCATE TABLE weapondeathsbyplayer;
TRUNCATE TABLE matchsquads;
TRUNCATE TABLE matchstreamers;
TRUNCATE TABLE playerstats;
TRUNCATE TABLE player;
TRUNCATE TABLE playernicks;
TRUNCATE TABLE playerhits;
TRUNCATE TABLE gamematch;
SET foreign_key_checks = 1;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

# Make SQL replica
DROP database IF EXISTS hlldwbackup;
CREATE DATABASE  IF NOT EXISTS `hlldwbackup` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci ;
create table hlldwbackup.clan SELECT * FROM hlldw.clan;
create table hlldwbackup.clansinmatch SELECT * FROM hlldw.clansinmatch;
create table hlldwbackup.clantag SELECT * FROM hlldw.clantag;
create table hlldwbackup.community SELECT * FROM hlldw.community;
create table hlldwbackup.competition SELECT * FROM hlldw.competition;
create table hlldwbackup.deathsbyplayer SELECT * FROM hlldw.deathsbyplayer;
create table hlldwbackup.gamematch SELECT * FROM hlldw.gamematch;
create table hlldwbackup.killsbyplayer SELECT * FROM hlldw.killsbyplayer;
create table hlldwbackup.map SELECT * FROM hlldw.map;
create table hlldwbackup.matchsquads SELECT * FROM hlldw.matchsquads;
create table hlldwbackup.matchstreamers SELECT * FROM hlldw.matchstreamers;
create table hlldwbackup.player SELECT * FROM hlldw.player;
create table hlldwbackup.playerhits SELECT * FROM hlldw.playerhits;
create table hlldwbackup.playernicks SELECT * FROM hlldw.playernicks;
create table hlldwbackup.playerstats SELECT * FROM hlldw.playerstats;
create table hlldwbackup.weapon SELECT * FROM hlldw.weapon;
create table hlldwbackup.weapondeathsbyplayer SELECT * FROM hlldw.weapondeathsbyplayer;
create table hlldwbackup.weaponkillsbyplayer SELECT * FROM hlldw.weaponkillsbyplayer;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

# Restore from replica

SHOW BINARY LOGS;
SHOW MASTER STATUS;

SET foreign_key_checks = 0;
truncate table hlldw.clan;
truncate table hlldw.clansinmatch;
truncate table hlldw.clantag;
truncate table hlldw.community;
truncate table hlldw.competition;
truncate table hlldw.deathsbyplayer;
truncate table hlldw.gamematch;
truncate table hlldw.killsbyplayer;
truncate table hlldw.map;
truncate table hlldw.matchsquads;
truncate table hlldw.matchstreamers;
truncate table hlldw.player;
truncate table hlldw.playerhits;
truncate table hlldw.playernicks;
truncate table hlldw.playerstats;
truncate table hlldw.weapon;
truncate table hlldw.weapondeathsbyplayer;
truncate table hlldw.weaponkillsbyplayer;
SET foreign_key_checks = 1;

INSERT INTO hlldw.clan SELECT * FROM hlldwbackup.clan;
INSERT INTO hlldw.clansinmatch SELECT * FROM hlldwbackup.clansinmatch;
INSERT INTO hlldw.clantag SELECT * FROM hlldwbackup.clantag;
INSERT INTO hlldw.community SELECT * FROM hlldwbackup.community;
INSERT INTO hlldw.competition SELECT * FROM hlldwbackup.competition;
INSERT INTO hlldw.deathsbyplayer SELECT * FROM hlldwbackup.deathsbyplayer;
INSERT INTO hlldw.gamematch SELECT * FROM hlldwbackup.gamematch;
INSERT INTO hlldw.killsbyplayer SELECT * FROM hlldwbackup.killsbyplayer;
INSERT INTO hlldw.map SELECT * FROM hlldwbackup.map;
INSERT INTO hlldw.matchsquads SELECT * FROM hlldwbackup.matchsquads;
INSERT INTO hlldw.matchstreamers SELECT * FROM hlldwbackup.matchstreamers;
INSERT INTO hlldw.player SELECT * FROM hlldwbackup.player;
INSERT INTO hlldw.playerhits SELECT * FROM hlldwbackup.playerhits;
INSERT INTO hlldw.playernicks SELECT * FROM hlldwbackup.playernicks;
INSERT INTO hlldw.playerstats SELECT * FROM hlldwbackup.playerstats;
INSERT INTO hlldw.weapon SELECT * FROM hlldwbackup.weapon;
INSERT INTO hlldw.weapondeathsbyplayer SELECT * FROM hlldwbackup.weapondeathsbyplayer;
INSERT INTO hlldw.weaponkillsbyplayer SELECT * FROM hlldwbackup.weaponkillsbyplayer;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;