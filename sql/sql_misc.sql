USE hlldw;

SELECT COUNT(*) FROM player;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

SELECT COUNT(*) FROM playerstats;
SELECT SUM(kills) FROM killsbyplayer;
SELECT SUM(deaths) FROM deathsbyplayer;

SELECT SUM(kills) FROM weaponkillsbyplayer;
SELECT SUM(Deaths) FROM weapondeathsbyplayer;
SELECT SUM(kills) FROM playerstats;
SELECT SUM(deaths) FROM playerstats;

SELECT * FROM player LIMIT 10;

#SELECT mapID FROM map WHERE MapKey='stmereeglise_warfare_night'

