USE hlldw;

SHOW SESSION VARIABLES LIKE 'character\_set\_%';
SHOW SESSION VARIABLES LIKE 'collation\_%';
SET collation_connection = @@collation_database;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

SELECT COUNT(*) FROM playerstats;
SELECT SUM(kills) FROM killsbyplayer;
SELECT SUM(deaths) FROM deathsbyplayer;

SELECT SUM(kills) FROM weaponkillsbyplayer;
SELECT SUM(Deaths) FROM weapondeathsbyplayer;
SELECT SUM(kills) FROM playerstats;
SELECT SUM(deaths) FROM playerstats;

SELECT * FROM playerstats LIMIT 10;

SELECT *
FROM playerstats a, playerstats b WHERE a.MatchID<>b.matchID AND a.SteamID=b.SteamID

SELECT *
FROM playerstats a
WHERE a.MatchID=5 AND a.SteamID NOT IN (SELECT b.SteamID from playerstats b WHERE b.MatchID=6)


#SELECT mapID FROM map WHERE MapKey='stmereeglise_warfare_night'


--Ver mismo jugador con SteamID y distinto nick en partidas cargadas
SELECT distinct a.Player,b.Player from
playerstats a, playerstats b WHERE a.SteamID=b.SteamID AND a.Player<>b.Player AND a.MatchID<b.matchID


SELECT * FROM playernicks
SELECT * FROM playerstats where matchID=52 LIMIT 10

SELECT distinct a.MatchID,a.Player,a.PlayerClanID,a.PlayerClanTag,d.Side,a.KillsByWeapons FROM playerstats a, gamematch b, weaponkillsbyplayer c, weapon d WHERE a.MatchID=b.MatchID AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;

SELECT * FROM weaponkillsbyplayer a WHERE a.weapon  not IN (SELECT DISTINCT weapon FROM weapon);

SELECT * from weaponkillsbyplayer where matchID IN (12,27,30,32)

SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID=10)<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID=10),1,0) AS DiffKill_Deaths;
SELECT b.ClanName,a.PlayerClanTag,a.PlayerClanID,a.* FROM playerstats a,clan b WHERE a.MatchID=10 AND a.PlayerClanID=b.ClanID
SELECT * FROM playerstats WHERE MatchID=10

SELECT * FROM playerstats WHERE player LIKE '%[%]%' AND PlayerClanID IS null


## Pruebas para módulo "Determinar y añadir matchsquads"
-- INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side)
SET @newMatchID=10;

#Determinar quienes han sido los comandantes
SELECT DISTINCT @newMatchID,a.player,a.SteamID,c.category1,c.category1,c.category1,a.PlayerSide FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE 
a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1='Commander';

#Blindados: regla # Tank = aquellos jugadores de la partida que hayan matado con armas de categoría1 Tank y esas kills sean >=20% de sus kills totales por jugador
SET @vCategory1='Tank',@vFormacion='Armored';
SET @weaponthreshold=0.20;
SELECT DISTINCT @newMatchID,a.player,a.SteamID,@vFormacion,c.category1,c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1
AND a.Player IN (SELECT a.Player FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 GROUP BY a.Player HAVING (SUM(b.Kills)/a.Kills)>=@weaponthreshold);


#Artillería: regla # Artillery = aquellos jugadores de la partida que hayan matado con armas de categoría1 Artillery y esas kills sean >=30% de sus kills totales por jugador
SET @vCategory1='Artillery',@vFormacion='Artillery';
SELECT DISTINCT @newMatchID,a.player,a.SteamID,@vFormacion,c.category1,c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1
AND a.Player IN (SELECT a.Player FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 GROUP BY a.Player HAVING (SUM(b.Kills)/a.Kills)>=0.30);

SET @vCategory1='Recon',@vFormacion='Recon';
SELECT DISTINCT @newMatchID,a.player,a.SteamID,@vFormacion,'Sniper',c.category1,a.PlayerSide
FROM playerstats a, weaponkillsbyplayer b, weapon c
WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1
AND a.Player IN (SELECT a.Player FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@newMatchID AND a.player=b.player AND a.MatchID=b.MatchID AND b.Weapon=c.Weapon AND c.category1=@vCategory1 GROUP BY a.Player HAVING (SUM(b.Kills)/a.Kills)>=0.50);


SET @newMatchID=76;
SELECT * FROM matchsquads WHERE matchID=@newMatchID

SELECT * FROM playerstats WHERE PlayerClanID IS NULL ORDER BY player

SELECT * FROM weaponkillsbyplayer WHERE matchID=3 AND player LIKE '%EKOBER%' ORDER BY kills desc