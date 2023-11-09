### WEB REPORT SCRIPTS for HLL DATAWAREHOUSE
# Generates web reports csv files to load to Looker Studio web reports 

USE hlldw;

SET collation_connection = @@collation_database;

#Match ID to get report€
SET @MatchID=3;

XXXXXXXXXXXXXXXXXXXXXXXX SECURE STOP XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

################################################################################################################################################################
# L1 - Match player list
SELECT a.CMID,a.MatchID,ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank,a.SteamID,a.Player,a.Kills,a.Deaths,a.TKs,a.KD,a.MaxKillStreak,a.KillsMin,a.DeathsMin,a.MaxDeathStreak,a.MaxTKStreak,a.DeathByTK,a.DeathByTKStreak,a.LongestLifeSec,a.ShortestLifeSec,a.MatchActiveTimeSec,
	a.PlayerClanTag,a.PlayerClanID,b.ClanAcro,
	CASE a.PlayerSide WHEN 1 THEN 'Allies' WHEN 2 THEN 'Axis' ELSE '' END AS PlayerSideName,a.CombatPoints,a.OffensePoints,a.DefensePoints,a.SupportPoints
FROM playerstats a LEFT JOIN clan b ON a.PlayerClanID=b.ClanID WHERE a.MatchID=@MatchID
ORDER BY a.Kills DESC;

# L2 - Game match info
SELECT g.CMID,g.MatchID,g.MatchDesc,g.ClansCoAllies,g.ClansCoAxis,g.StartTime,g.EndTime,round(g.DurationSec/60,0) AS DurationMin,g.RCONMapName,g.ResultAllies,g.ResultAxis,g.MatchType,m.MatchTypeDesc,g.CompetitionID,c.CompetitionName,c.CompetitionOrga
FROM gamematch g, competition c, matchtype m WHERE g.MatchID=@MatchID AND g.CompetitionID=c.CompetitionID AND g.MatchType=m.MatchType
