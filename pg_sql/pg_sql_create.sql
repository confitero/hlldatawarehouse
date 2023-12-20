-- ### CREATE SCHEMA SCRIPTS FOR HLL DATAWAREHOUSE (Postgresql version)

CREATE ROLE uhlldw PASSWORD 'XXXXXXXXXXXXXXX' LOGIN;

CREATE DATABASE hlldw WITH OWNER uhlldw encoding 'UTF-8' template template0;

CREATE SCHEMA hlldw;

-- ****************************************************************************************************************************************************************************
-- STATIC DATA TABLES

-- -----------------------------------------------------
-- Table `Map`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS map (
  MapID SMALLINT NOT NULL,
  MapName VARCHAR(50) NOT NULL,
  MapKey VARCHAR(50) NOT NULL,
  MapDesc VARCHAR(100) NOT NULL,
  CONSTRAINT map_pk PRIMARY KEY (MapID));

COMMENT ON COLUMN map.MapID is 'Map identifier for this DB';
COMMENT ON COLUMN map.MapName is 'Map place in English / local';
COMMENT ON COLUMN map.MapKey is 'HLL RCON Map key name';
COMMENT ON COLUMN map.MapDesc iS 'Map description';
COMMENT ON TABLE map IS 'Game maps';

-- -----------------------------------------------------
-- Table `MatchType`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS MatchType (
  MatchType SMALLINT NOT NULL,
  MatchTypeDesc VARCHAR(45) NOT NULL,
  CONSTRAINT pk_matchtype PRIMARY KEY (MatchType)
);
CREATE UNIQUE INDEX ix_matchtype_unique ON matchtype USING btree (matchtype);
CREATE UNIQUE INDEX ix_matchtypedesc_unique ON matchtype USING btree (matchtypedesc);
COMMENT ON COLUMN matchtype.matchtype IS 'Match type: 0 = Casual; 1 = Friendly; 2 = Competitive';
COMMENT ON COLUMN matchtype.matchtypedesc IS 'Description of match type: 0 = Casual; 1 = Friendly; 2 = Competitive';

-- -----------------------------------------------------
-- Table `Community`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Community (
  CMID INT NOT NULL,
  CommunityName VARCHAR(50) NOT NULL,
  CONSTRAINT idx_community_pk PRIMARY KEY (CMID)
);
CREATE UNIQUE INDEX idx_community_cmid_uq ON community USING btree (cmid);
CREATE UNIQUE INDEX idx_community_communityname_uq ON community USING btree (communityname);
COMMENT ON COLUMN community.cmid IS 'Game Community internal database ID';
COMMENT ON COLUMN community.communityname IS 'Game Community name (unique)';

-- -----------------------------------------------------
-- Table `Competition`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Competition (
  CompetitionID INT NOT NULL,
  CompetitionName VARCHAR(100) NOT NULL,
  CompetitionOrga VARCHAR(50) NOT NULL,
  CONSTRAINT competition_pk PRIMARY KEY (CompetitionID)
);
COMMENT ON COLUMN competition.competitionid IS '1 record = 1 competition edition (i.e. HLL Seasonal Sprint 2024)';
COMMENT ON COLUMN competition.competitionname IS 'Competition Phase Name, i.e. HCA-2022 week 5';
COMMENT ON COLUMN competition.competitionorga IS 'Competition orga (i.e. HLL Seasonal / ECL / HCA)';

-- -----------------------------------------------------
-- Table `Clan`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Clan (
  ClanID SMALLINT NOT NULL,
  ClanName VARCHAR(100) NOT NULL,
  Country VARCHAR(50) NULL,
  LastHeloRank SMALLINT NULL,
  ClanAcro VARCHAR(20) NOT NULL,
  CONSTRAINT clan_pk PRIMARY KEY (clanid)
);

-- -----------------------------------------------------
-- Table `ClanTag`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS ClanTag (
  ClanTag VARCHAR(15) NOT NULL,
  ClanID SMALLINT NOT NULL,
  CONSTRAINT clantag_pk PRIMARY KEY (ClanTag),
  CONSTRAINT fkClanTag_Clan_ClanID FOREIGN KEY (ClanID) REFERENCES Clan (ClanID) ON DELETE RESTRICT ON UPDATE RESTRICT
);
CREATE INDEX idx_clantag_clanid ON hlldw.clantag USING btree (clanid);
COMMENT ON COLUMN clantag.clantag IS 'Clan tag must be unique. If collision between two or more clans, use aditional prefix/sufix to made unique (country, region, continent, etc)';

-- -----------------------------------------------------
-- Table `Weapon`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Weapon (
  WeaponID INT NOT NULL,
  Weapon VARCHAR(500) NULL,
  Category1 VARCHAR(50) NOT NULL,
  Category2 VARCHAR(50) NOT NULL,
  Category3 VARCHAR(50) NOT NULL,
  Side1 VARCHAR(50) NOT NULL,
  Side2 VARCHAR(50) NOT NULL,
  Model VARCHAR(50) NOT NULL,
  WeaponFull VARCHAR(80) NOT NULL,
  Side SMALLINT NOT NULL,
  CONSTRAINT weapon_pk PRIMARY KEY (WeaponID)  
);
CREATE UNIQUE INDEX idx_weapon_uq ON weapon USING btree (weapon);


-- ****************************************************************************************************************************************************************************
-- VAR DATA TABLES

-- -----------------------------------------------------
-- Table `GameMatch`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS GameMatch (
  MatchID BIGSERIAL NOT NULL,
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
  CompetitionID INT NOT NULL DEFAULT '0'::int,
  CONSTRAINT gamematch_pk PRIMARY KEY (MatchID),
  CONSTRAINT fkgamematch_competitionid FOREIGN KEY (competitionid) REFERENCES competition(competitionid) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fkgamematch_mapid FOREIGN KEY (mapid) REFERENCES map(mapid) ON DELETE RESTRICT ON UPDATE RESTRICT
);
CREATE INDEX ix_gamematch_competitionid ON gamematch USING btree (competitionid);
CREATE INDEX ix_gamematch_mapid ON gamematch USING btree (mapid);
--ix_gamematch_sqlInsertMatch original carga pg_load fue BTREE
CREATE INDEX ix_gamematch_sqlInsertMatch ON gamematch USING HASH (CMID,RCONMatchID,StartTime,EndTime);

COMMENT ON COLUMN gamematch.matchid IS 'Internal database match ID / Identificador único en la base de datos de este partido';
COMMENT ON COLUMN gamematch.cmid is 'Community/Clan database ID that hosted this match (see Community table)';
COMMENT ON COLUMN gamematch.RCONMatchID IS 'Field \"result\".\"id\" from match JSON stats (unique to RCON database)';
COMMENT ON COLUMN gamematch.MatchName IS 'Match name (Comp+Teams)';
COMMENT ON COLUMN gamematch.MatchDesc IS 'Match description';
COMMENT ON COLUMN gamematch.ClansCoAllies IS 'Coalition of clans in allies side';
COMMENT ON COLUMN gamematch.ClansCoAxis IS 'Coalition of clans in axis side';
COMMENT ON COLUMN gamematch.StartTime IS 'Match start datetime (year; month; day; hh; mm; ss)';
COMMENT ON COLUMN gamematch.EndTime IS 'Match end datetime (year; month; day; hh; mm; ss)';
COMMENT ON COLUMN gamematch.DurationSec IS 'Match duration in seconds';
COMMENT ON COLUMN gamematch.RCONMapName IS 'Match map name-code from RCON JSON';
COMMENT ON COLUMN gamematch.RCONServerNumber IS 'Match server number 1 to N when one RCON instance manages several game servers';
COMMENT ON COLUMN gamematch.StatsUrl IS 'URL of match stats webpage';
COMMENT ON COLUMN gamematch.JSONStatsURL IS 'URL of match stats JSON RCON API';
COMMENT ON COLUMN gamematch.GameServerName IS 'HLL Server name';
COMMENT ON COLUMN gamematch.GameServerIP IS 'HLL Server IP';
COMMENT ON COLUMN gamematch.GameServerOwner IS 'HLL game server owner (i.e clan name; community; etc)';
COMMENT ON COLUMN gamematch.MapID IS 'Map ID (see Map table)';
COMMENT ON COLUMN gamematch.ResultAllies IS 'Match result for Allies team: 0-5';
COMMENT ON COLUMN gamematch.ResultAxis IS 'Match result for Axis team: 0-5';
COMMENT ON COLUMN gamematch.MatchType IS '0 = Casual; 1 = Friendly/Amistoso; 2 = Competitive/Competitivo';
COMMENT ON COLUMN gamematch.CompetitionID IS 'Competition Phase ID (0 = casual)';

-- -----------------------------------------------------
-- Table `ClansInMatch`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS ClansInMatch (
  MatchID BIGINT NOT NULL,
  ClanID SMALLINT NOT NULL,
  Side SMALLINT NOT NULL,
  CONSTRAINT clansinmatch_pk PRIMARY KEY (MatchID, ClanID, Side),
  CONSTRAINT fkClansInMatch_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fkClansInMatch_ClanID FOREIGN KEY (ClanID) REFERENCES Clan (ClanID) ON DELETE RESTRICT ON UPDATE RESTRICT
);
CREATE INDEX ix_clansinmatch_clanid ON hlldw.clansinmatch USING BTREE (clanid);
CREATE INDEX ix_clansinmatch_matchid ON hlldw.clansinmatch USING BTREE (matchid);
COMMENT ON COLUMN clansinmatch.side is  '1 Allies; 2 Axis / One clan can play the match balanced between the two sides';

-- -----------------------------------------------------
-- Table `Player`
-- -----------------------------------------------------
CREATE TABLE player (
	DWPlayerID VARCHAR(30) NOT NULL,
	SteamID VARCHAR(30) NOT NULL,
	Rank SMALLINT NOT NULL DEFAULT 0,
	CONSTRAINT player_pk PRIMARY KEY (DWPlayerID)
);
create INDEX ix_Player_SteamID ON player USING HASH (SteamID); -- Original en carga pg_load fue BTREE
COMMENT ON COLUMN player.dwplayerid is 'Database internal player ID';

-- -----------------------------------------------------
-- Table `PlayerStats`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS PlayerStats (
	CMID INT NOT NULL,
	MatchID INT NOT NULL,
	Player VARCHAR(50) NOT NULL,
	DWPlayerID VARCHAR(30) NOT NULL,
	RCONPlayerID INT NOT NULL,
	SteamID VARCHAR(30) NOT NULL,
	Kills SMALLINT NOT NULL,
	Deaths SMALLINT NOT NULL,
	TKs SMALLINT NOT NULL,
	KD FLOAT4 NOT NULL,
	MaxKillStreak SMALLINT NOT NULL,
	KillsMin FLOAT4 NOT NULL,
	DeathsMin FLOAT4 NOT NULL,
	MaxDeathStreak SMALLINT NOT NULL,
	MaxTKStreak SMALLINT NOT NULL,
	DeathByTK SMALLINT NOT NULL,
	DeathByTKStreak SMALLINT NOT NULL,
	LongestLifeSec SMALLINT NOT NULL,
	ShortestLifeSec SMALLINT NOT NULL,
	MatchActiveTimeSec INT NOT NULL,
	Nemesis TEXT NOT NULL,
	Victims TEXT NOT NULL,
	PlayerClanTag VARCHAR(15) NULL,
	KillsByWeapons TEXT(65447) NOT NULL,
	DeathsByWeapons TEXT(65447) NOT NULL,
	PlayerClanID SMALLINT NULL,
	PlayerSide SMALLINT NULL,
	CombatPoints SMALLINT NOT NULL,
	OffensePoints SMALLINT NOT NULL,
	DefensePoints SMALLINT NOT NULL,
	SupportPoints SMALLINT NOT NULL,
	CONSTRAINT playerstats_pk PRIMARY KEY (CMID, MatchID, Player),
	CONSTRAINT fkPlayerStats_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE RESTRICT ON UPDATE RESTRICT,
	CONSTRAINT fkPlayerStats_DWPlayerID FOREIGN KEY (DWPlayerID) REFERENCES Player (DWPlayerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
	CONSTRAINT fkPlayerStats_CMID FOREIGN KEY (CMID) REFERENCES Community (CMID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX ix_playerstats_1 ON playerstats USING btree (matchid, player, playerside, deaths);
CREATE INDEX ix_playerstats_2 ON playerstats USING btree (matchid, player, steamid, playerside);
CREATE INDEX ix_playerstats_3 ON playerstats USING btree (matchid, player, kills);
CREATE INDEX ix_playerstats_4 ON playerstats USING btree (matchid, player, deaths);
CREATE INDEX ix_playerstats_5 ON playerstats USING btree (matchid, steamid);
CREATE INDEX ix_playerstats_id_player ON playerstats USING btree (dwplayerid, player);


COMMENT ON COLUMN playerstats.CMID IS 'Community/Clan database ID (see Community table)';
COMMENT ON COLUMN playerstats.MatchID IS 'DB Match ID';
COMMENT ON COLUMN playerstats.Player IS 'Player''s game nick (Steam Nick) as shown in HLL C-RCON stats';
COMMENT ON COLUMN playerstats.DWPlayerID IS 'Database internal Player ID';
COMMENT ON COLUMN playerstats.RCONPlayerID IS 'RCON Stats JSON \"player_id\"';
COMMENT ON COLUMN playerstats.SteamID IS 'Player''s Steam ID64 (not always available)';
COMMENT ON COLUMN playerstats.Kills IS 'Enemy kills made by player';
COMMENT ON COLUMN playerstats.Deaths IS 'Player deaths in that match excluded redeploy deaths as that is not logged by HLL C-RCON)';
COMMENT ON COLUMN playerstats.TKs IS 'Team kills made by player';
COMMENT ON COLUMN playerstats.KD IS 'Kill vs deaths ratio by player / JSON \"kill_death_ratio\"';
COMMENT ON COLUMN playerstats.MaxKillStreak IS 'Max kills streak made by player before first death or between two deaths / JSON \"kills_streak\"';
COMMENT ON COLUMN playerstats.KillsMin IS 'Kills made by player per minute / JSON \"kills_per_minute\"';
COMMENT ON COLUMN playerstats.DeathsMin IS 'Número de muertas por minuto sufridas por el jugador / JSON \"deaths_per_minute\"';
COMMENT ON COLUMN playerstats.MaxDeathStreak IS 'Max death streak by player with zero kills made in that life / Mayor racha de muertes sufridas por el jugador sin haber matado enemigos / JSON \"deaths_without_kill_streak\"';
COMMENT ON COLUMN playerstats.MaxTKStreak IS 'Max team kill streak by player in one life / Mayor racha de bajas de fuego amigo causadas por el jugador sin morir / JSON \"teamkills_streak\"';
COMMENT ON COLUMN playerstats.DeathByTK IS 'Times the player has been killed by a team member / Bajas de fuego amigo sufridas por el jugador';
COMMENT ON COLUMN playerstats.DeathByTKStreak IS 'Times the player has been killed by a team member in one life / Bajas de fuego amigo sufridas por el jugador sin haber causado bajas al enemigo';
COMMENT ON COLUMN playerstats.LongestLifeSec IS 'Longest player life in seconds / Vida más larga del jugador en segundos desde que aparece hasta que es asesinado / JSON \"longest_life_secs\"';
COMMENT ON COLUMN playerstats.ShortestLifeSec IS 'Shortest player life in seconds / Vida más corta del jugador en segundos desde que aparece hasta que es asesinado / JSON \"shortest_life_secs\"';
COMMENT ON COLUMN playerstats.MatchActiveTimeSec IS 'Sum of seconds active by player (lives) / JSON \"time_seconds\"';
COMMENT ON COLUMN playerstats.Nemesis IS 'JSON field with all deaths by player (player, killer, weapon, num of deaths) / Campo JSON en bruto con los Killers de este jugador';
COMMENT ON COLUMN playerstats.Victims IS 'JSON field with all kills by player (player, victim, weapon, num of kills) / Campo JSON en bruto las víctimas de este jugador';
COMMENT ON COLUMN playerstats.PlayerClanTag IS 'Tag del jugador en esa partida. Guardarlo aquí evita perder el clan con el que jugó esta partida si cambia de clan posteriormente';
COMMENT ON COLUMN playerstats.KillsByWeapons IS 'JSON field with all kills by player (player, weapon, num of deaths)  / Campo JSON en bruto con las bajas efectuadas por este jugador con cada arma utilizada';
COMMENT ON COLUMN playerstats.DeathsByWeapons IS 'JSON field with all deaths by player (player, weapon, num of deaths)  / Campo JSON en bruto con las bajas sufridas por este jugador con cada arma utilizada / JSON \"death_by_weapons\"';
COMMENT ON COLUMN playerstats.PlayerClanID IS 'Clan del jugador en esa partida. Guardarlo aquí evita perder el clan con el que jugó esta partida si cambia de clan posteriormente';
COMMENT ON COLUMN playerstats.PlayerSide IS '1 allies / 2 axis';
COMMENT ON COLUMN playerstats.CombatPoints IS 'Combat points the player won in the match';
COMMENT ON COLUMN playerstats.OffensePoints IS 'Offense points the player won in the match';
COMMENT ON COLUMN playerstats.DefensePoints IS 'Defense points the player won in the match';
COMMENT ON COLUMN playerstats.SupportPoints IS 'Support points the player won in the match';

-- -----------------------------------------------------
-- Table `KillsByPlayer`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS KillsByPlayer (
  MatchID BIGINT  NOT NULL,
  Killer VARCHAR(50) NOT NULL,
  Victim VARCHAR(50) NOT NULL,
  Kills SMALLINT NOT NULL,
  CONSTRAINT fkKills_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE RESTRICT ON UPDATE RESTRICT
);

create INDEX ix_KillsByPlayer_1 ON KillsByPlayer USING BTREE (MatchID); --Prev: HASH
-- BTree TYPE because of terms max(Kills) that requires order of rows
create INDEX ix_KillsByPlayer_2 ON KillsByPlayer USING BTREE (MatchID,Kills);
create INDEX ix_KillsByPlayer_3 ON KillsByPlayer USING BTREE (MatchID,Killer); --Prev: HASH
create INDEX ix_KillsByPlayer_4 ON KillsByPlayer USING BTREE (MatchID,Victim); --Prev: HASH

COMMENT ON COLUMN killsbyplayer.MatchID IS 'Identificador único del partido de estos resultados del jugador';
COMMENT ON COLUMN killsbyplayer.Killer IS 'Player game nick that has killed the victim / Nombre del jugador en Steam-HLL que ha causado estas bajas a la Victim en este partido';
COMMENT ON COLUMN killsbyplayer.Victim IS 'Player game nick death by killer / Nombre del jugador en Steam-HLL que ha sufrido muertes por el Killer en ese partido';
COMMENT ON COLUMN killsbyplayer.Kills IS 'Num of deaths the killer has killed the victim in this match / Número de veces que el Killer ha matado a la Victim en este partido';

-- -----------------------------------------------------
-- Table `DeathsByPlayer`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS DeathsByPlayer (
  MatchID BIGINT NOT NULL,
  Victim VARCHAR(50) NOT NULL,
  Killer VARCHAR(50) NOT NULL,
  Deaths SMALLINT UNSIGNED NOT NULL,
  CONSTRAINT fkDeaths_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- BTree TYPE because of terms max(Deaths) that requires order of rows
create INDEX ix_DeathsByPlayer_sqlFillPlayerMatchSide ON DeathsByPlayer USING BTREE (MatchID,Victim,Killer,Deaths);
create INDEX ix_DeathsByPlayer_1 ON DeathsByPlayer USING BTREE (MatchID); --Prev: HASH
-- BTree TYPE because of terms max(Deaths) that requires order of rows
create INDEX ix_DeathsByPlayer_2 ON DeathsByPlayer USING BTREE (MatchID,Deaths);
create INDEX ix_DeathsByPlayer_3 ON DeathsByPlayer USING BTREE (MatchID,Killer); --Prev: HASH
create INDEX ix_DeathsByPlayer_4 ON DeathsByPlayer USING BTREE (MatchID,Victim); --Prev: HASH

COMMENT ON COLUMN deathsbyplayer.MatchID IS 'Identificador único del partido de estos resultados del jugador';
COMMENT ON COLUMN deathsbyplayer.Victim IS 'Player game nick death by killer / Nombre del jugador en Steam/HLL que ha sufrido muertes en este partido por parte del Killer';
COMMENT ON COLUMN deathsbyplayer.Killer IS 'Player game nick that has killed the victim / Nombre del jugador en Steam/HLL que ha matado a la Victim en este partido';
COMMENT ON COLUMN deathsbyplayer.Deaths IS 'Num of deaths the killer has killed the victim in this match / Número de veces que la Victim ha muerto por este Killer en este partido'; 

-- -----------------------------------------------------
-- Table WeaponKillsByPlayer
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS WeaponKillsByPlayer (
  MatchID BIGINT NOT NULL,
  Player VARCHAR(50) NOT NULL,
  Weapon VARCHAR(500) NOT NULL,
  Kills SMALLINT NOT NULL,
  CONSTRAINT fkWeaponKills_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE RESTRICT ON UPDATE RESTRICT
);

-- BTree TYPE because of terms max(Kills) that requires order of rows
create INDEX ix_WeaponKillsByPlayer_1 ON WeaponKillsByPlayer USING BTREE (MatchID,Weapon,Player,Kills);
create INDEX ix_WeaponKillsByPlayer_2 ON WeaponKillsByPlayer USING BTREE (MatchID);--Prev: HASH
create INDEX ix_WeaponKillsByPlayer_3 ON WeaponKillsByPlayer USING BTREE (MatchID,Player);--Prev: HASH

COMMENT ON COLUMN weaponkillsbyplayer.MatchID IS 'Identificador único del partido de estos resultados del jugador';
COMMENT ON COLUMN weaponkillsbyplayer.Player IS 'Player game nick that has win this kills by this weapon / Nombre del jugador en Steam/HLL que ha causado estas bajas enemigas en este partido';
COMMENT ON COLUMN weaponkillsbyplayer.Weapon IS 'Name of weapon / Arma con la que el jugador ha causado las bajas';
COMMENT ON COLUMN weaponkillsbyplayer.Kills IS 'Num of kills got by player with this weapon in this match / Número de bajas que el jugador ha causado en este partido con el arma concreta';

-- -----------------------------------------------------
-- Table PlayerNicks
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS PlayerNicks (
  SteamID VARCHAR(30) NOT NULL,
  PlayerNick VARCHAR(50) NOT NULL,
  MainNick bool NOT NULL,
  CONSTRAINT playernicks_pk PRIMARY KEY (SteamID, PlayerNick)
);

COMMENT on column playernicks.PlayerNick IS 'Player Steam nick'; 
COMMENT on column playernicks.MainNick IS '1 = main nick / 0 = secondary nick used in some matches';

-- -----------------------------------------------------
-- Table MatchSquads
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS MatchSquads (
  MatchID BIGINT NOT NULL,
  Player VARCHAR(50) NOT NULL,
  SteamID VARCHAR(30) NOT NULL,
  SquadRole VARCHAR(50) NOT NULL,
  PlayerRole VARCHAR(50) NOT NULL,
  SquadName VARCHAR(50) NOT NULL,
  Side SMALLINT NULL,  
  CONSTRAINT fk_MatchSquads_GameMatch_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE RESTRICT ON UPDATE RESTRICT
);
CREATE INDEX ix_matchsquads_matchid ON matchsquads USING btree (matchid);

-- -----------------------------------------------------
-- Table PlayerHits >>>>>>>> reserved for future use in logs analyzer
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS PlayerHits (
  MatchID BIGINT NOT NULL,
  Player VARCHAR(50) NOT NULL,
  Victim VARCHAR(50) NOT NULL,
  Weapon VARCHAR(500) NOT NULL,
  HitTime timestamptz NOT NULL,
  "type" VARCHAR(50) NULL,
  CONSTRAINT playerhits_pk PRIMARY KEY (MatchID),
  CONSTRAINT fk_PlayerHits_GameMatch FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE UNIQUE INDEX ix_matchsquads_1 ON playerhits USING btree (matchid, player);

-- -----------------------------------------------------
-- Table WeaponDeathsByPlayer
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS WeaponDeathsByPlayer (
  MatchID BIGINT NOT NULL,
  Player VARCHAR(50) NOT NULL,
  Weapon VARCHAR(500) NOT NULL,
  Deaths SMALLINT NOT NULL,
  CONSTRAINT fkWeaponDeathsByPlayer_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- BTree TYPE because of terms max(Deaths) that requires order of rows
CREATE INDEX ix_WeaponDeathsByPlayer_1 ON WeaponDeathsByPlayer USING BTREE (MatchID,Weapon,Player,Deaths);
CREATE INDEX ix_WeaponDeathsByPlayer_matchidx ON WeaponDeathsByPlayer USING btree (matchid);

COMMENT ON COLUMN WeaponDeathsByPlayer.Player IS 'Player game nick that has been killed by this weapon / Nombre del jugador en Steam/HLL que ha muerto por esa arma';
COMMENT ON COLUMN WeaponDeathsByPlayer.Weapon IS 'Name of weapon / Arma con la que el jugador ha muerto';
COMMENT ON COLUMN WeaponDeathsByPlayer.Deaths IS 'Num of deaths got by player with this weapon in this match / Número de bajas que el jugador ha sufrido en este partido con el arma concreta';

-- -----------------------------------------------------
-- Table MatchStreamers
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS MatchStreamers (
  MatchID BIGINT NOT NULL,
  SteamID VARCHAR(30) NOT NULL,
  Side TINYINT UNSIGNED NOT NULL,
  CastURL VARCHAR(2048) NULL,
  CONSTRAINT matchstreamers_pk PRIMARY KEY (MatchID, SteamID),
  CONSTRAINT fk_MatchStreamers_MatchID FOREIGN KEY (MatchID) REFERENCES GameMatch (MatchID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

COMMENT ON COLUMN MatchStreamers.Side IS '1 Allies; 2 Axis; 0 both';


-- -----------------------------------------------------
-- Table `hll_log`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS hll_log (
	ts datetime,
	tlog TEXT
)

-- *****************************************************************************************************************************
-- DB Procedures
-- *****************************************************************************************************************************



-- *****************************************************************************************************************************
