-- ### DATA SCRIPTS FOR LOAD NEW MATCHES into the HLL DATAWAREHOUSE

#TODO Translate comments to english
/* PROCEDIMIENTO
0) Lanzar un full backup de la BD
1) Rellenar manualmente partida en tabla GameMatch
2) Si hay clanes nuevos, cargarlos en tabla clan y cargar la etiqueta del nuevo clan en clantag
3) Rellenar clanes de partida en clansinmatch
4) Ejecutar programa Python de carga de stats partida desde URL del RCON de HLL
4.1) Para indicar la url y otros datos de la partida a cargar, poner fila única con URL de stats a cargar en el archivo "HLL Datawarehouse\app\matchstats_loader\HLL_DW_ETL_list.csv"
4.2) Ejecutar la carga con "HLL Datawarehouse\app\matchstats_loader\python HLL_DW_ETL_main.py"
4.3) Revisar errores en archivo "HLL Datawarehouse\app\matchstats_loader\HLL_DW.log" y corregir si los hay
5) Revisar las tablas cargadas (playerstats tiene el número de jugadores de la partida y se han cargado killsbyplayer, weaponkillsbyplayer y deathsbyplayer) >> AÑADIR nuevas armas si no están catalogadas
6) Si hay jugadores con nuevo TAG de clan, cargar en clantag
7) Normalizar nombre jugador en tablas de stats
8) Ver si hay jugadores en stats con nicks secundarios que corregir
9) Revisar que cuadran kills y deaths de playerstats con las tablas adicionales
10) Corregir nicks y tag de los streamers
11) Rellenar playerstats.PlayerTag y playerstats.ClanID
*/

#*****************************************************************************
#### MATCH LOAD

#New Match variables
SET @newMatchID=XX;
SET @first_match=1,@second_match=1; -- For two phase matches (home and away). Equal values for only phase match
SET @CMID=1; -- Community or clan database
SET @RCONMatchID=1526327;
SET @MatchName='Test';
SET @MatchDesc='Test carga Comunidad Hispana Casual SME';
SET @ClansCoAllies = ''; -- Acronym for allies side clan coallition or group of players
SET @ClansCoAxis = ''; -- Acronym for axis side clan coallition or group of players
SET @StartTime = 'AAAA-MM-DD HH:MM:SS'; -- Match start time format: '2023-04-23 11:30:00'
SET @StartTime = '2023-10-24 17:02:41'; -- Match start time format: '2023-04-23 11:30:00'
SET @EndTime = '2023-10-24 18:32:46'; -- Match start time format: '2023-04-23 11:30:00'
SET @DurationSec = 5400; -- 5400 = 90 minutes
SET @RCONMapName = 'stmereeglise_warfare_night';
SET @RCONServerNumber = '1';
SET @StatsUrl = 'https://server.comunidadhll.es:5443/#/gamescoreboard/1526327'; -- Format: http://<ip_or_dns>:<port>/#/gamescoreboard/<match_id>
SET @JSONStatsURL = ''; -- Format: http://<ip_or_dns>:<port>/api/get_map_scoreboard?map_id=<match_id>
SET @GameServerName = '';
SET @GameServerIP = '';
SET @GameServerOwner = '';
SET @MapID = 4; -- From table map
SET @ResultAllies = '5'; -- Values 0 to 5
SET @ResultAxis = '0'; -- Values 0 to 5
SET @MatchType = '0'; -- 0 = Casual; 1 = Friendly/Amistoso; 2 = Competitive/Competitivo
SET @CompetitionID = 0; -- From table competition


SHOW SESSION VARIABLES LIKE 'character\_set\_%';
SHOW SESSION VARIABLES LIKE 'collation\_%';
SET collation_connection = @@collation_database;


## 0) Lanzar full backup
## >>> 

## 1) Rellenar partida en tabla GameMatch
INSERT INTO gamematch (MatchID,CMID, RCONMatchID, MatchName, MatchDesc, ClansCoAllies, ClansCoAxis, StartTime, EndTime, DurationSec, RCONMapName, RCONServerNumber, StatsUrl, JSONStatsURL, GameServerName, GameServerIP, GameServerOwner, MapID, ResultAllies, ResultAxis, MatchType, CompetitionID) VALUES
(@newMatchID,@CMID,@RCONMatchID,@MatchName,@MatchDesc,@ClansCoAllies, @ClansCoAxis, @StartTime, @EndTime, @DurationSec, @RCONMapName, @RCONServerNumber, @StatsUrl, @JSONStatsURL, @GameServerName, @GameServerIP,@GameServerOwner, @MapID, @ResultAllies, @ResultAxis, @MatchType, @CompetitionID);

## 2) Si hay clanes nuevos en esta partida, cargarlos en la tabla clan
## >>> 

## 3) Rellenar clanes que han jugado esta partida en tabla ClansInMatch
INSERT INTO clansinmatch (MatchID,ClanID,Side) VALUES (@newMatchID,,1); -- Allies side
INSERT INTO clansinmatch (MatchID,ClanID,Side) VALUES (@newMatchID,,2); -- Axis side


## 4) Ejecutar programa Python de carga de stats partida desde URL

## 4.1) Poner fila única con URL de stats a cargar en el archivo E:\onedrive\personal\OneDrive\Juegos\HLL Datawarehouse\app\matchstats_loader\HLL_DW_ETL_list.csv
## Añadir esta línea y comentar el resto: <match_server_id> <match_filename> <stats_url>

## 4.2) Ejecutar la carga con el programa Python:
## >>> c:\python E:\onedrive\personal\OneDrive\Juegos\HLL Datawarehouse\app\matchstats_loader\python HLL_DW_ETL_main.py

## 4.3) Revisar errores en archivo HLL_DW.log y corregir si los hay
## >>> 

## 5) Revisar las tablas cargadas (playerstats tiene el número de jugadores de la partida y se han cargado killsbyplayer, weaponkillsbyplayer y deathsbyplayer)
SELECT * FROM playerstats WHERE matchID=@newMatchID;

# >>> COMPROBACIONES POST CARGA EN PYTHON

## El número devuelto por las siguientes consultas debe ser el mismo (muertes/kills en todas las tablas de la partida)
SELECT SUM(kills) FROM killsbyplayer WHERE matchID=@newMatchID;
SELECT SUM(deaths) FROM deathsbyplayer WHERE matchID=@newMatchID;
SELECT SUM(kills) FROM weaponkillsbyplayer WHERE matchID=@newMatchID;
SELECT SUM(Deaths) FROM weapondeathsbyplayer WHERE matchID=@newMatchID;
SELECT SUM(kills) FROM playerstats WHERE matchID=@newMatchID;
SELECT SUM(deaths) FROM playerstats WHERE matchID=@newMatchID;
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y killsbyplayer en "KILLS"
SELECT * FROM playerstats a, (SELECT x1.Killer AS Player,SUM(x1.Kills) AS SumKills FROM killsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Killer) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Kills<>b.SumKills;
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y deathsbyplayer en "DEATHS"
SELECT * FROM playerstats a, (SELECT x1.Victim AS Player,SUM(x1.Deaths) AS SumDeaths FROM deathsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Victim) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Deaths<>b.SumDeaths;
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y killsbyplayer en "KILLS"
SELECT * FROM playerstats a, (SELECT x1.Player AS Player,SUM(x1.Kills) AS SumKills FROM weaponkillsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Player) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Kills<>b.SumKills;
## Revisar si cuadran otras tablas. Si no devuelven filas, están cuadradas correctamente
SELECT * FROM killsbyplayer WHERE matchID=@newMatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM killsbyplayer WHERE matchID=@newMatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM deathsbyplayer WHERE matchID=@newMatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM deathsbyplayer WHERE matchID=@newMatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM weaponkillsbyplayer WHERE matchID=@newMatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM weapondeathsbyplayer WHERE matchID=@newMatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);


#Si hay armas nuevas no catalogadas, añadirlas
## Buscar nuevas armas en las stats
SELECT * FROM weaponkillsbyplayer a WHERE a.matchID=@newMatchID AND a.weapon NOT IN (SELECT DISTINCT weapon FROM weapon);
## Insertar las nuevas armas
INTO Weapon (Weapon,Category1,Category2,Category3,Side1,Side2,Model) VALUES ('WEAPONNAME','CATEGORY1','CATEGORY2','CATEGORY3','SIDE1','SIDE2','MODEL','FULLNAME')

## 6) Si hay jugadores con nuevo TAG de clan de apoyo, cargar en ClanTag: 
INSERT INTO clantag (ClanID,ClanTag) VALUES (<CLAN_ID>,'[TAG]');


## 7) Normalizar nombre jugador en tablas de stats
UPDATE playerstats SET player=TRIM(player) WHERE matchID=@newMatchID;
UPDATE weaponkillsbyplayer SET player=TRIM(player) WHERE matchID=@newMatchID;
UPDATE weaponkillsbyplayer SET weapon=TRIM(weapon) WHERE matchID=@newMatchID;
UPDATE weapondeathsbyplayer SET player=TRIM(player) WHERE matchID=@newMatchID;
UPDATE weapondeathsbyplayer SET weapon=TRIM(weapon) WHERE matchID=@newMatchID;
UPDATE killsbyplayer SET killer=TRIM(killer) WHERE matchID=@newMatchID;
UPDATE killsbyplayer SET victim=TRIM(victim) WHERE matchID=@newMatchID;
UPDATE deathsbyplayer SET killer=TRIM(killer) WHERE matchID=@newMatchID;
UPDATE deathsbyplayer SET victim=TRIM(victim) WHERE matchID=@newMatchID;

## 8.1) Analizar y corregir jugadores sin tag de clan o con tags no identificados en la base de datos:
SELECT * FROM playerstats WHERE matchID=@newMatchID AND player not IN (SELECT distinct x.player FROM playerstats x, clantag y, clan z where locate(y.clantag,x.Player)>0 AND y.ClanID=z.ClanID AND x.MatchID=@newMatchID)


## 8.2) Cargar qué jugadores han sido los streamers de la partida
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,XXXXXXSTEAMIDXXXXXXXX, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX); -- 1 Allies; 2 Axis; 0 both

-- Streamers habituales:
-- Sultan
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198045609300, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- Queco
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198277901186, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- -TL- Pepper
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198164001169, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
--Berserkr#2468
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198077183657, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- [DC] Kinderic
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198188021214, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- 🅶 I|I FeatTony3
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198011198956, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- λλ | Buffonator
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561198125642854, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);
-- [1.Fjg] ele`
INSERT INTO matchstreamers (MatchID,SteamID,Side,CastURL) VALUES (@newMatchID,76561197960739379, XXXXXXXSideXXXXXXX, XXXXXXXCastURLXXXXXXXX);

	
# 9) Revisar que cuadran kills y deaths de playerstats con las tablas adicionales
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y killsbyplayer en "KILLS"
SELECT * FROM playerstats a, (SELECT x1.Killer AS Player,SUM(x1.Kills) AS SumKills FROM killsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Killer) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Kills<>b.SumKills;
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y deathsbyplayer en "DEATHS"
SELECT * FROM playerstats a, (SELECT x1.Victim AS Player,SUM(x1.Deaths) AS SumDeaths FROM deathsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Victim) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Deaths<>b.SumDeaths;
## La siguiente consulta no debe devolver nada. Si devuelve tuplas, son las que están descuadradas entre playerstats y killsbyplayer en "KILLS"
SELECT * FROM playerstats a, (SELECT x1.Player AS Player,SUM(x1.Kills) AS SumKills FROM weaponkillsbyplayer x1 WHERE x1.matchID=@newMatchID GROUP BY x1.Player) AS b WHERE a.matchID=@newMatchID AND a.player=b.player AND a.Kills<>b.SumKills;
## Revisar si cuadran otras tablas. Si no devuelven filas, están cuadradas correctamente
SELECT * FROM killsbyplayer WHERE matchID=@newMatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM killsbyplayer WHERE matchID=@newMatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM deathsbyplayer WHERE matchID=@newMatchID AND victim NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM deathsbyplayer WHERE matchID=@newMatchID AND killer NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM weaponkillsbyplayer WHERE matchID=@newMatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);
SELECT * FROM weapondeathsbyplayer WHERE matchID=@newMatchID AND player NOT IN (SELECT player FROM playerstats WHERE matchID=@newMatchID);


# 11) Rellenar playerstats.PlayerTag y playerstats.ClanID y playerStats.Side

##11.1) Comprobar en la siguiente consulta que están todos los 100 jugadores de la partida (más de 100 si ha habido alguna sustitución en medio de la partida)
SELECT distinct x.player,y.clantag,z.ClanName AS CompClan FROM playerstats x, clantag y, clan z where locate(y.clantag,x.Player)>0 AND y.ClanID=z.ClanID AND x.MatchID=@newMatchID;

##11.2) RELLENAR EL CLAN Y TAG DE CADA JUGADOR
UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0 AND x.MatchID=@newMatchID;

##11.3) RELLENAR EL BANDO DE CADA JUGADOR EN LA PARTIDA a partir del bando de su clan
SELECT a.MatchID,a.Player,a.PlayerClanID,a.PlayerClanTag,c.Side FROM playerstats a, gamematch b, clansinmatch c WHERE a.MatchID=b.MatchID AND b.MatchID=c.MatchID AND a.PlayerClanID=c.ClanID AND a.MatchID=@newMatchID;
UPDATE playerstats a, gamematch b, clansinmatch c SET a.PlayerSide=c.Side WHERE a.MatchID=b.MatchID AND b.MatchID=c.MatchID AND a.PlayerClanID=c.ClanID AND a.MatchID=@newMatchID;
UPDATE playerstats a SET a.PlayerSide=0 WHERE a.MatchID=@newMatchID AND EXISTS (SELECT 1 FROM matchstreamers x WHERE a.MatchID=x.MatchID AND a.SteamID=x.SteamID);

##11.4) RELLENAR EL BANDO DE CADA JUGADOR EN LA PARTIDA a partir del bando de sus armas, sobreescribiendo los anteriores
SELECT distinct a.MatchID,a.Player,a.PlayerClanID,a.PlayerClanTag,d.Side FROM playerstats a, gamematch b, weaponkillsbyplayer c, weapon d WHERE a.MatchID=b.MatchID AND a.MatchID=@newMatchID AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;
UPDATE playerstats a, gamematch b, weaponkillsbyplayer c, weapon d SET a.PlayerSide=d.Side WHERE a.MatchID=b.MatchID AND a.MatchID=@newMatchID AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;

##11.5) RELLENAR EL BANDO DE CADA JUGADOR EN LA PARTIDA a partir del bando de las armas que les han matado, si no tiene kills y tiene muertes, sobreescribiendo los anteriores
SELECT distinct a.MatchID,a.Player,a.Kills,a.Deaths,a.PlayerClanID,a.PlayerClanTag,a.PlayerSide,d.Side,a.DeathsByWeapons FROM playerstats a, weapondeathsbyplayer c, weapon d WHERE a.MatchID=@newMatchID AND a.Kills=0 AND a.Deaths>0 AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;
SELECT * FROM playerstats WHERE matchID=63 AND player='Alwarteru'
UPDATE playerstats a, weapondeathsbyplayer b, weapon c SET a.PlayerSide=2 WHERE a.MatchID=@newMatchID AND a.Kills=0 AND a.Deaths>0 AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.side=1;
UPDATE playerstats a, weapondeathsbyplayer b, weapon c SET a.PlayerSide=1 WHERE a.MatchID=@newMatchID AND a.Kills=0 AND a.Deaths>0 AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.side=2;


##11.6) Verificar que NO ha quedado ningún jugador (no streamers) sin bando
SELECT CASE when PlayerSide=1 then 'Allies' WHEN PlayerSide=2 then 'Axis' when PlayerSide=0 then 'Streamers' ELSE 'NO side' END AS Side,COUNT(*) AS Jugadores FROM playerstats WHERE matchID=@newMatchID GROUP BY PlayerSide;
SELECT MatchID,SteamID,player,PlayerClanTag,PlayerClanID,PlayerSide FROM playerstats WHERE matchID=@newMatchID AND PlayerSide NOT IN (1,2);
SELECT MatchID,SteamID,player,PlayerClanTag,PlayerClanID,PlayerSide FROM playerstats WHERE matchID=@newMatchID;


########Carga de formación DESCONOCIDA (automática)
SET @ExcluirReglasClanID='ID1,ID2,ID3'; # SET @ExcluirReglasClanID=NUM >>>>>>>> Para excluir el clan con ese ID y así introducir manualmente la formación detallada  | 0 para meter todos los clanes

#Comandantes: regla # Comandante = aquellos jugadores de la partida que hayan matado con armas de categoría1 Comandante
INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side) SELECT DISTINCT @newMatchID,a.player,a.SteamID,c.category1,c.category1,c.category1,a.PlayerSide FROM playerstats a, weaponkillsbyplayer b, weapon c where
 a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1='Commander' AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0;

#Blindados: regla # Tank = aquellos jugadores de la partida que hayan matado con armas de categoría1 Tank y esas kills sean >=20% de sus kills totales por jugador
INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SELECT DISTINCT @newMatchID,a.player,a.SteamID,'Armored',c.category1,c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1='Tank' AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
AND a.Player IN (
SELECT a.Player
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1='Tank' AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
GROUP BY a.Player
HAVING (SUM(b.Kills)/a.Kills)>=0.20)

#Artillería: regla # Artillery = aquellos jugadores de la partida que hayan matado con armas de categoría1 Artillery y esas kills sean >=30% de sus kills totales por jugador
SET @vCategory1='Artillery',@vFormacion='Artillery';
INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SELECT DISTINCT @newMatchID,a.player,a.SteamID,@vFormacion,c.category1,c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
AND a.Player IN (
SELECT a.Player
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
GROUP BY a.Player
HAVING (SUM(b.Kills)/a.Kills)>=0.30)

#Francotirador: regla # Recon = aquellos jugadores de la partida que hayan matado con armas de categoría1 Recon y esas kills sean >=50% de sus kills totales por jugador
SET @vCategory1='Recon',@vFormacion='Recon';
INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SELECT DISTINCT @newMatchID,a.player,a.SteamID,@vFormacion,'Sniper',c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
AND a.Player IN (
SELECT a.Player
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
GROUP BY a.Player
HAVING (SUM(b.Kills)/a.Kills)>=0.50)

#AT-Sniping: regla # Aquellos jugadores de la partida que hayan matado con armas de categoría3 'AT rocket launcher' y esas kills sean >=50% de sus kills totales por jugador
/* INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SELECT DISTINCT @newMatchID,a.player,a.SteamID,'AT sniping','AT Sniper','AT sniping',a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category3='AT rocket launcher' AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
AND a.Player IN (
SELECT a.Player
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category3='AT rocket launcher' AND FIND_IN_SET(a.PlayerClanID,@ExcluirReglasClanID)>0
GROUP BY a.Player
HAVING (SUM(b.Kills)/a.Kills)>=0.50) */

#Infantería: regla # Aquellos jugadores de la partida que no estén catalogados en los roles anteriores y no sean streamers
INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SELECT DISTINCT @newMatchID,a.player,a.SteamID,'Infantry','Infantry','Infantry',a.PlayerSide
FROM playerstats a
WHERE a.MatchID=@newMatchID AND a.PlayerClanID<>@ExcluirReglasClanID
AND a.Player not IN (SELECT DISTINCT x.Player FROM matchsquads x WHERE x.MatchID=@newMatchID)
AND a.PlayerClanID<>77

################******************************************************************************************
######### Consultas de comprobación final de carga

SELECT * FROM matchsquads WHERE MatchID=@newMatchID ORDER BY player;

SELECT a.MatchID,a.Player,b.Player,b.SquadRole,b.PlayerRole,b.SquadName,b.Side,a.Kills,a.Deaths,a.TKs,a.Weapons FROM playerstats a, matchsquads b WHERE a.MatchID=@newMatchID AND a.MatchID=b.MatchID AND a.SteamID=b.SteamID ORDER BY a.Player


## Ver nuevos jugadores de esta partida en la tabla de jugadores únicos "Player"
SELECT * FROM playerstats a WHERE a.matchID=@newMatchID AND a.player NOT IN (SELECT nick FROM player) AND a.SteamID NOT IN (SELECT SteamID FROM player)
SELECT * FROM playerstats a WHERE a.matchID=@newMatchID AND a.player NOT IN (SELECT nick FROM player) AND a.SteamID IN (SELECT SteamID FROM player)
SELECT DISTINCT SteamID,player,'1' AS MainNick FROM playerstats WHERE SteamID>0 AND MatchID=@newMatchID AND SteamID NOT IN (SELECT SteamID FROM player)
#-- AND player LIKE '501.es |%'
#Normalizar nicks de jugadores
>>>>>>>>>>>>>>>>> INSERT INTO player (SteamID,Nick,MainNick) SELECT DISTINCT SteamID,player,1 FROM playerstats WHERE SteamID>0 AND MatchID=@newMatchID AND SteamID NOT IN (SELECT SteamID FROM player)

SELECT * FROM playerstats WHERE matchID=@newMatchID
SELECT * FROM weaponkillsbyplayer WHERE matchID=@newMatchID


#Carga de formación CONOCIDA (manual)
SELECT a.MatchID,a.Player,a.SteamID FROM playerstats a WHERE a.MatchID=@newMatchID AND a.PlayerClanID=37 ORDER BY a.Player asc

## Ver nuevos jugadores de esta partida en la tabla de jugadores únicos "Player"
SELECT * FROM playerstats a WHERE a.matchID=@newMatchID AND a.player NOT IN (SELECT nick FROM player) AND a.SteamID NOT IN (SELECT SteamID FROM player)
SELECT * FROM playerstats a WHERE a.matchID=@newMatchID AND a.player NOT IN (SELECT nick FROM player) AND a.SteamID IN (SELECT SteamID FROM player)
#Normalizar nicks de jugadores
>>>>>>>>>>>>>>>>> INSERT INTO player SELECT DISTINCT SteamID,player,'1' FROM playerstats WHERE SteamID>0 AND a.matchID=@newMatchID AND player NOT IN (SELECT nick FROM player) AND SteamID NOT IN (SELECT SteamID FROM player)

SELECT * FROM playerstats WHERE matchID=@newMatchID
SELECT * FROM weaponkillsbyplayer WHERE matchID=@newMatchID


**********************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END LOAD SCRIPTS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
