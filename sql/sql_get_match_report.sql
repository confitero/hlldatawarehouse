-- ### MATCH REPORT SCRIPTS for HLL DATAWAREHOUSE

##? >>>>>>>>>>>>>>>> Copy rows to clipboard (HeidiSQL Windows): Ctrl+Alt+E

SET collation_connection = @@collation_database;

#Match ID to get report
SET @MatchID=6;

################################################################################################################################################################
# L1 - Match player list

SELECT ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank,a.MatchID,a.SteamID,a.Player,a.Kills,a.Deaths,a.TKs,a.KD,a.MaxKillStreak,a.KillsMin,a.DeathsMin,a.MaxDeathStreak,a.MaxTKStreak,a.DeathByTK,a.DeathByTKStreak,a.LongestLifeSec,a.ShortestLifeSec,a.MatchActiveTimeSec,a.PlayerClanTag,a.PlayerClanID,a.PlayerSide
FROM playerstats a WHERE a.MatchID=@MatchID ORDER BY a.Kills DESC;

-- Percentile calculate method 2
/*SELECT a.Player,ROUND(100.0 * (SELECT COUNT(*) FROM playerstats x WHERE x.Kills <= a.Kills) / totals.Player_count, 1) AS percentile
FROM playerstats a
CROSS JOIN (SELECT COUNT(*) AS Player_count FROM playerstats) AS totals
ORDER BY percentile DESC;*/

# L2 - Match info report
SELECT 'Result' AS 'Desc',concat(ResultAllies,'-',ResultAxis,
	CASE WHEN ResultAllies>ResultAxis THEN ' (winner Allies)'
	WHEN ResultAllies<ResultAxis THEN ' (winner Axis)'
	ELSE ' (draw)' END)
	AS 'Info' FROM gamematch WHERE matchID=@MatchID 
UNION
SELECT 'Teams',concat(ClansCoAllies ,' / ',ClansCoAxis) FROM gamematch WHERE matchID=@MatchID 
UNION 
SELECT 'Map',m.MapDesc FROM gamematch g, `map` m WHERE g.MatchID=@MatchID AND g.MapID=m.MapID 
UNION 
SELECT 'Competition',c.CompetitionName FROM gamematch g, competition c WHERE g.MatchID=@MatchID AND g.CompetitionID=c.CompetitionID
UNION 
SELECT 'Date and duration',concat(date(g.StartTime),' / ',round(g.DurationSec/60,0),' min') FROM gamematch g WHERE g.MatchID=@MatchID
 

	
# L3 - Squads - number of players report
SELECT b.SquadRole,b.PlayerRole,
sum(CASE b.Side when 1 then 1 ELSE 0 END) AS 'Allies',
sum(CASE b.Side when 2 then 1 ELSE 0 END) AS 'Axis',
COUNT(*) AS 'Total'
FROM playerstats a, matchsquads b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.SteamID=b.SteamID AND b.Side IN (1,2)
GROUP BY b.SquadRole,b.PlayerRole


# L4 Percentile report
SELECT '>=95%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 95 AND 100
union
SELECT '90-94%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 90 AND 94.99
union
SELECT '76-89%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 76 AND 89.99
union
SELECT '50-75%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 50 AND 75.99
union
SELECT '25-50%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 25 AND 49.99
union
SELECT '10-25%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 10 AND 24.99
UNION
SELECT '6-10%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 6 AND 9.99
union
SELECT '<=5%' AS 'Percentile',sum(case x.Side when 'Allies' then 1 ELSE 0 end) AS Allies,sum(case x.Side when 'Axis' then 1 ELSE 0 end) AS Axis FROM (SELECT case a.PlayerSide when 1 then 'Allies' when 2 then 'Axis' ELSE '' END AS 'Side',ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY a.Kills),1) as percentile_rank FROM playerstats a where a.MatchID=@MatchID) AS X WHERE x.percentile_rank BETWEEN 0 AND 5.99


################################################################################################################################################################
# R0 - Team Points report

# R0s1 Team Points
SELECT
	 'Total team offensive points' AS Type,
	 sum(case a.PlayerSide when 1 then a.OffensePoints ELSE 0 END) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.OffensePoints ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 'Total team defensive points' AS Type,
	 sum(case a.PlayerSide when 1 then a.DefensePoints ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.DefensePoints ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 'Total team combat points' AS Type,
	 sum(case a.PlayerSide when 1 then a.CombatPoints ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.CombatPoints ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 'Total team support points' AS Type,
	 sum(case a.PlayerSide when 1 then a.SupportPoints ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.SupportPoints ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 'TOTAL TEAM POINTS' AS Type,
	 sum(case a.PlayerSide when 1 then a.OffensePoints+a.DefensePoints+a.CombatPoints+a.SupportPoints ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.OffensePoints+a.DefensePoints+a.CombatPoints+a.SupportPoints  ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
# Offensive/players (OP=players who have more offense points than defense points) >>>>>>> Effectivenes = CombatPoints + SupportPoints
SELECT
	 'OFFENSIVE PLAYERS' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,1,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,1,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Offensive players total offense points' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.OffensePoints,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.OffensePoints,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Offensive players total defense points' AS Type,
	 SUM(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.DefensePoints,0) END) AS 'Allies',
	 SUM(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.DefensePoints,0) END) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Offensive players total combat points' AS Type,
	 SUM(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.CombatPoints,0) END) AS 'Allies',
	 SUM(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.CombatPoints,0) END) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Offensive players total support points' AS Type,
	 SUM(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.SupportPoints,0) END) AS 'Allies',
	 SUM(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.SupportPoints,0) END) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
# Defensive players (OP=players who have more offense points than defense points) >>>>>>> Effectivenes = CombatPoints + SupportPoints
SELECT
	 'DEFENSIVE PLAYERS' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.DefensePoints>=a.OffensePoints,1,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.DefensePoints>=a.OffensePoints,1,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Defensive players total offense points' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.DefensePoints>=a.OffensePoints,a.OffensePoints,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.DefensePoints>=a.OffensePoints,a.OffensePoints,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Defensive players total defense points' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.DefensePoints>=a.OffensePoints,a.DefensePoints,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.DefensePoints>=a.OffensePoints,a.DefensePoints,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Deffensive players total combat points' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.DefensePoints>=a.OffensePoints,a.CombatPoints,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.DefensePoints>=a.OffensePoints,a.CombatPoints,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Defensive players total support points' AS Type,
	 sum(case a.PlayerSide when 1 then if(a.DefensePoints>=a.OffensePoints,a.SupportPoints,0) end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then if(a.DefensePoints>=a.OffensePoints,a.SupportPoints,0) end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID;


#R0s2 AVG per player (side)
SELECT
	 '    Offense points per player (avg)' AS Type,
	 sum(case a.PlayerSide when 1 then a.OffensePoints ELSE 0 end) / sum(case a.PlayerSide when 1 then 1 ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.OffensePoints ELSE 0 end) / sum(case a.PlayerSide when 2 then 1 ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Defense points per player (avg)' AS Type,
	 sum(case a.PlayerSide when 1 then a.DefensePoints ELSE 0 end) / sum(case a.PlayerSide when 1 then 1 ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.DefensePoints ELSE 0 end) / sum(case a.PlayerSide when 2 then 1 ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Combat points per player (avg)' AS Type,
	 sum(case a.PlayerSide when 1 then a.CombatPoints ELSE 0 end) / sum(case a.PlayerSide when 1 then 1 ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.CombatPoints ELSE 0 end) / sum(case a.PlayerSide when 2 then 1 ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT
	 '    Support points per player (avg)' AS Type,
	 sum(case a.PlayerSide when 1 then a.SupportPoints ELSE 0 end) / sum(case a.PlayerSide when 1 then 1 ELSE 0 end) AS 'Allies',
	 sum(case a.PlayerSide when 2 then a.SupportPoints ELSE 0 end) / sum(case a.PlayerSide when 2 then 1 ELSE 0 end) AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID;

# R0s3 Points per player type Offensive/Defensive (avg)
SET @NumOffensivePlayers_Allies=(SELECT count(*) AS NumOffensivePlayers FROM playerstats a WHERE a.MatchID=@MatchID AND a.PlayerSide=1 AND a.OffensePoints>a.DefensePoints);
SET @NumOffensivePlayers_Axis=(SELECT count(*) AS NumOffensivePlayers FROM playerstats a WHERE a.MatchID=@MatchID AND a.PlayerSide=2 AND a.OffensePoints>a.DefensePoints);
SET @NumDefensivePlayers_Allies=(SELECT count(*) AS NumDefensivePlayers FROM playerstats a WHERE a.MatchID=@MatchID AND a.PlayerSide=1 AND a.OffensePoints<=a.DefensePoints);
SET @NumDefensivePlayers_Axis=(SELECT count(*) AS NumDefensivePlayers FROM playerstats a WHERE a.MatchID=@MatchID AND a.PlayerSide=2 AND a.OffensePoints<=a.DefensePoints);
	# R0s3a Points per player type Offensive (avg)
	SELECT
		'    Offense points per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.OffensePoints,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.OffensePoints,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Defense points per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.DefensePoints,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.DefensePoints,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Combat points per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.CombatPoints,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.CombatPoints,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Support points per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.SupportPoints,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.SupportPoints,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Kills per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.Kills,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.Kills,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Deaths per offensive player (avg)' AS Type,
		 IF(@NumOffensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints>a.DefensePoints,a.Deaths,0) END) / @NumOffensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumOffensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints>a.DefensePoints,a.Deaths,0) END) / @NumOffensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID;

	# R0s3b Points per player type Defensive (avg)
	SELECT
		'    Offense points per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.OffensePoints,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.OffensePoints,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Defense points per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.DefensePoints,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.DefensePoints,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Combat points per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.CombatPoints,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.CombatPoints,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Support points per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.SupportPoints,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.SupportPoints,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Kills per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.Kills,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.Kills,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID
	UNION
	SELECT
		 '    Deaths per defensive player (avg)' AS Type,
		 IF(@NumDefensivePlayers_Allies>0,sum(case a.PlayerSide when 1 then if(a.OffensePoints<=a.DefensePoints,a.Deaths,0) END) / @NumDefensivePlayers_Allies,0) AS 'Allies',
	 	 IF(@NumDefensivePlayers_Axis>0,sum(case a.PlayerSide when 2 then if(a.OffensePoints<=a.DefensePoints,a.Deaths,0) END) / @NumDefensivePlayers_Axis,0) AS 'Axis'
	FROM playerstats a WHERE a.MatchID=@MatchID;



# Effectiveness (% of combat+support points relative to num of players by side)
SELECT
round(100.0*round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END)/sum(case a.PlayerSide when 1 then 1 ELSE  0 END),2)
/((round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END)/sum(case a.PlayerSide when 1 then 1 ELSE  0 END),2))+(round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end)/sum(case a.PlayerSide when 2 then 1 ELSE  0 END),2))),2)
 AS 'Allies',
round(100.0*round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end)/sum(case a.PlayerSide when 2 then 1 ELSE  0 END),2)
/((round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END)/sum(case a.PlayerSide when 1 then 1 ELSE  0 END),2))+(round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end)/sum(case a.PlayerSide when 2 then 1 ELSE  0 END),2))),2)
AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID;

# Effectiveness (% of combat+support points)
SELECT
round(100.0*round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END),2)
/((round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END),2))+(round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end),2))),2)
 AS 'Allies',
round(100.0*round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end),2)
/((round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END),2))+(round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end),2))),2)
AS 'Axis'
FROM playerstats a WHERE a.MatchID=@MatchID;

# Sum of player points by side
SELECT 'Effectiveness' AS Type,round(sum(case a.PlayerSide when 1 then a.CombatPoints+a.SupportPoints ELSE  0 END),2) AS 'Allies',round(sum(case a.PlayerSide when 2 then a.CombatPoints+a.SupportPoints ELSE  0 end),2) AS 'Axis',round(SUM(a.CombatPoints+a.SupportPoints),2) AS 'Total efectividad'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT 'Offense' AS Type,round(sum(case a.PlayerSide when 1 then a.OffensePoints ELSE  0 END),2) AS 'Allies',round(sum(case a.PlayerSide when 2 then a.OffensePoints ELSE  0 end),2) AS 'Axis',round(SUM(a.OffensePoints),2) AS 'Total offense'
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT 'Defense' AS Type,round(sum(case a.PlayerSide when 1 then a.DefensePoints ELSE  0 END),2) AS 'Allies',round(sum(case a.PlayerSide when 2 then a.DefensePoints ELSE  0 end),2) AS 'Axis',round(SUM(a.DefensePoints),2) AS 'Total defense'
FROM playerstats a WHERE a.MatchID=@MatchID


# Number of players by side and total
SELECT sum(case a.PlayerSide when 1 then 1 ELSE  0 END) AS 'Allies',sum(case a.PlayerSide when 2 then 1 ELSE  0 END) AS 'Axis',COUNT(*) AS 'Total efectividad'
FROM playerstats a WHERE a.MatchID=@MatchID


################################################################################################################################################################
# R1 - Match results by team report page

#R1S1: Match results
SELECT 'Kills',SUM(if(PlayerSide=1,Kills,0)) as 'Allies',SUM(if(PlayerSide=2,Kills,0)) AS 'Axis',SUM(Kills) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Deaths',SUM(if(PlayerSide=1,Deaths,0)) as 'Allies',SUM(if(PlayerSide=2,Deaths,0)) AS 'Axis',SUM(Deaths) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'TKs',SUM(if(PlayerSide=1,TKs,0)) as 'Allies',SUM(if(PlayerSide=2,TKs,0)) AS 'Axis',SUM(TKs) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'KD (avg)',AVG(if(PlayerSide=1,KD,0)) as 'Allies',AVG(if(PlayerSide=2,KD,0)) AS 'Axis',AVG(KD) AS 'Total' FROM playerstats WHERE MatchID=@MatchID;

#Alt: trasp table Match Results Total
/*
SELECT 'Allies',
SUM(CASE WHEN a.PlayerSide=1 THEN a.Kills ELSE 0 END) Kills,
SUM(CASE WHEN a.PlayerSide=1 THEN a.Deaths ELSE 0 END) Deaths,
SUM(CASE WHEN a.PlayerSide=1 THEN a.TKs ELSE 0 END) TKs,
SUM(CASE WHEN a.PlayerSide=1 THEN a.Kills/a.Deaths ELSE 0 END) KD
FROM playerstats a WHERE a.MatchID=@MatchID
UNION
SELECT 'Axis',
SUM(CASE WHEN a.PlayerSide=2 THEN a.Kills ELSE 0 END) Kills,
SUM(CASE WHEN a.PlayerSide=2 THEN a.Deaths ELSE 0 END) Deaths,
SUM(CASE WHEN a.PlayerSide=2 THEN a.TKs ELSE 0 END) TKs,
SUM(CASE WHEN a.PlayerSide=2 THEN a.Kills/a.Deaths ELSE 0 END) KD
FROM playerstats a WHERE a.MatchID=@MatchID;
*/

#********** >>>>>>>>>>> To CHECK: verify allies side kills = axis side deaths


#R1S2: Maximums by single player
SELECT 'Max Kills' AS Data,max(if(PlayerSide=1,Kills,0)) as 'Allies',max(if(PlayerSide=2,Kills,0)) AS 'Axis',max(Kills) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Deaths',max(if(PlayerSide=1,Deaths,0)) as 'Allies',max(if(PlayerSide=2,Deaths,0)) AS 'Axis',max(Deaths) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Kill Streak',max(if(PlayerSide=1,MaxKillStreak,0)) as 'Allies',max(if(PlayerSide=2,MaxKillStreak,0)) AS 'Axis',max(MaxKillStreak) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Kills/min',max(if(PlayerSide=1,KillsMin,0)) as 'Allies',max(if(PlayerSide=2,KillsMin,0)) AS 'Axis',max(KillsMin) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Death Streak',max(if(PlayerSide=1,MaxDeathStreak,0)) as 'Allies',max(if(PlayerSide=2,MaxDeathStreak,0)) AS 'Axis',max(MaxDeathStreak) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Longest Life',max(if(PlayerSide=1,LongestLifeSec/60,0)) as 'Allies',max(if(PlayerSide=2,LongestLifeSec/60,0)) AS 'Axis',max(LongestLifeSec/60) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Time in match',max(if(PlayerSide=1,MatchActiveTimeSec/60,0)) as 'Allies',max(if(PlayerSide=2,MatchActiveTimeSec/60,0)) AS 'Axis',max(MatchActiveTimeSec/60) AS 'Total' FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Max Nemesis Kills',max(if(a.PlayerSide=1,c.MaxUniqueKillsByPlayer,0)) AS 'Allies',max(if(a.PlayerSide=2,c.MaxUniqueKillsByPlayer,0)) AS 'Axis',max(c.MaxUniqueKillsByPlayer) AS 'Total'
FROM playerstats a, killsbyplayer b, (SELECT x.PlayerSide,max(y.kills) AS MaxUniqueKillsByPlayer FROM playerstats x, killsbyplayer y WHERE x.matchID=@MatchID AND x.matchID=y.matchID AND x.Player=y.Killer GROUP BY x.PlayerSide) AS c
WHERE a.MatchID=@MatchID AND a.Player=b.Killer AND b.Kills=c.MaxUniqueKillsByPlayer AND a.MatchID=b.MatchID AND a.PlayerSide=c.PlayerSide


#R1S3: Averages by side
SELECT M.DATA,M.Allies,M.Axis,N.MatchTotal
from
(SELECT 'Kills' AS DATA, sum(if(Side='Allies',Kills,0)) AS 'Allies', sum(if(Side='Axis',Kills,0)) AS 'Axis'
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side, AVG(Kills) AS 'Kills' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA
UNION
SELECT 'Deaths' AS Data,sum(if(Side='Allies',Deaths,0)) AS 'Allies',sum(if(Side='Axis',Deaths,0)) AS 'Axis' 
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side,AVG(Deaths) AS 'Deaths' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA
UNION
SELECT 'KD' AS Data,sum(if(Side='Allies',KD,0)) AS 'Allies',sum(if(Side='Axis',KD,0)) AS 'Axis' 
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side,AVG(KD) AS 'KD' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA
UNION
SELECT 'TKs' AS Data,sum(if(Side='Allies',TKs,0)) AS 'Allies',sum(if(Side='Axis',TKs,0)) AS 'Axis' 
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side,AVG(TKs) AS 'TKs' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA
UNION
SELECT 'LongestLifeSec' AS Data,sum(if(Side='Allies',LongestLifeSec,0)) AS 'Allies',sum(if(Side='Axis',LongestLifeSec,0)) AS 'Axis' 
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side,AVG(LongestLifeSec)/60 AS 'LongestLifeSec' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA
UNION
SELECT 'MatchActiveTimeSec' AS Data,sum(if(Side='Allies',MatchActiveTimeSec,0)) AS 'Allies',sum(if(Side='Axis',MatchActiveTimeSec,0)) AS 'Axis' 
FROM (SELECT CASE PlayerSide WHEN 1 then 'Allies' WHEN 2 then 'Axis' ELSE '' END AS Side,AVG(MatchActiveTimeSec)/60 AS 'MatchActiveTimeSec' FROM playerstats WHERE MatchID=@MatchID AND PlayerSide IN (1,2) GROUP BY Side) X
GROUP BY DATA) AS M,
(SELECT 'Kills' AS DATA,AVG(Kills) AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'Deaths' AS DATA,AVG(Deaths) AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'KD' AS DATA,AVG(KD) AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'TKs' AS DATA,AVG(TKs) AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'LongestLifeSec' AS DATA,AVG(LongestLifeSec)/60 AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID
UNION
SELECT 'MatchActiveTimeSec' AS DATA,AVG(MatchActiveTimeSec)/60 AS 'MatchTotal'
FROM playerstats WHERE MatchID=@MatchID) AS N
WHERE M.DATA=N.DATA;


#R1S4: Winner
SELECT 'SectorsControlled' AS DataType,if(ResultAllies>ResultAxis,ResultAllies,ResultAxis) AS Data,case when ResultAllies>ResultAxis then 'Allies' ELSE 'Axis' END AS 'WinnerSide'
from gamematch a WHERE a.MatchID=@MatchID
UNION
(SELECT * FROM (SELECT 'Kills' AS DataType,sum(b.Kills) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'TKs' AS DataType,sum(b.TKs) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'TopKiller' AS DataType,b.kills as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2)) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'MaxKillStreak' AS DataType,max(b.MaxKillStreak) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'KillsMin' AS DataType,max(b.KillsMin) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'TopLongestLifeMin' AS DataType,max(b.LongestLifeSec/60) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(SELECT * FROM (SELECT 'TopTimeInMatch' AS DataType,max(b.MatchActiveTimeSec/60) as Data,case b.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side'
from gamematch a,playerstats b WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND b.PlayerSide IN (1,2) GROUP BY b.PlayerSide) AS X ORDER BY DATA desc LIMIT 1)
UNION
(select * FROM (SELECT 'TopNemesisKiller' AS DataType,max(y.kills) as Data,case x.PlayerSide when 1 then 'Allies' ELSE 'Axis' END AS 'Side' FROM playerstats x, killsbyplayer y WHERE x.matchID=@MatchID AND x.matchID=y.matchID AND x.Player=y.Killer GROUP BY x.PlayerSide) AS X ORDER BY DATA DESC LIMIT 1)


################################################################################################################################################################
# R2 - Weapon and Role Match results report

#R2S1: Kills by weapon (top 15)
SELECT c.WeaponFull,SUM(b.Kills) AS KillsByWeapon
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon
GROUP BY c.WeaponFull ORDER BY sum(b.kills) DESC LIMIT 15

#R2S2: Kills by weapon role Category 2 - Side
SELECT c.Category1,c.Category2,
sum(CASE WHEN a.PlayerSide=1 then b.Kills ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then b.Kills ELSE 0 END) 'Axis',
SUM(b.Kills) 'Total'
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon
GROUP BY c.Category1,c.Category2 ORDER BY c.Category1,c.Category2;


#R2S3: Kills by weapon role Category 1 - Side
SELECT c.Category1,
sum(CASE WHEN a.PlayerSide=1 then b.Kills ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then b.Kills ELSE 0 END) 'Axis',
SUM(b.Kills) 'Total'
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon
GROUP BY c.Category1 ORDER BY c.Category1;

################################################################################################################################################################
# R3 - Tank results report

#R3S1: Kills by weapon tank (top 15)
SELECT c.WeaponFull,SUM(b.Kills) AS KillsByWeapon
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.Category1='Tank'
GROUP BY c.WeaponFull ORDER BY sum(b.kills) DESC LIMIT 15;

#R3S2: Kills by tank type
SELECT c.Category1,c.Category2,
sum(CASE WHEN a.PlayerSide=1 then b.Kills ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then b.Kills ELSE 0 END) 'Axis',
SUM(b.Kills) 'Total'
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.Category1='Tank'
GROUP BY c.Category1,c.Category2 order BY c.Category1,c.Category2;

#R3S3: Weapon tank type kills
SELECT c.Category3,
sum(CASE WHEN a.PlayerSide=1 then b.Kills ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then b.Kills ELSE 0 END) 'Axis',
SUM(b.Kills) 'Total'
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.Category1='Tank'
GROUP BY c.Category3;

#R3S4: Weapon tank model kills - Allies
SELECT c.Model,SUM(b.Kills) AS KillsByWeapon
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.Category1='Tank' AND a.PlayerSide=1
GROUP BY c.Model;

#R3S4: Weapon tank model kills - Axis
SELECT c.Model,SUM(b.Kills) AS KillsByWeapon
FROM playerstats a, weaponkillsbyplayer b, weapon c WHERE a.MatchID=@MatchID AND a.matchID=b.matchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.Category1='Tank' AND a.PlayerSide=2
GROUP BY c.Model;

#******************************************************************************************************************************#
# R4 - Player Match results report

#R4S1: Kills by player (top 15) - Top Match Killer
SELECT a.player,a.Kills FROM playerstats a
WHERE a.MatchID=@MatchID
ORDER BY a.kills DESC LIMIT 15;

#R4S2: TOP KD by player (top 15)
SELECT a.player,a.KD FROM playerstats a
WHERE a.MatchID=@MatchID
ORDER BY a.KD DESC LIMIT 15;

#R4S3: Less Deaths by player (top 15)
SELECT a.player,a.Deaths FROM playerstats a
WHERE a.MatchID=@MatchID AND a.PlayerSide IN (1,2)
ORDER BY a.Deaths ASC LIMIT 15;

#******************************************************************************************************************************#
# R5 - Infantry - Player & WEAPON Match results

#R5s1: Player by weapon (top 15)
SELECT a.weapon,a.player,a.Kills FROM weaponkillsbyplayer a, (SELECT x.weapon,MAX(x.kills) AS MaxKillsByWeapon FROM weaponkillsbyplayer x WHERE x.MatchID=@MatchID GROUP BY x.weapon) b
WHERE a.weapon=b.Weapon AND a.kills=b.MaxKillsByWeapon AND a.MatchID=@MatchID
ORDER BY a.kills DESC LIMIT 15;

#R5s2: Player by weapon type (top 15)
SELECT b.category3,a.player,a.Kills FROM weaponkillsbyplayer a, (SELECT y.category3,MAX(x.kills) AS MaxKillsByWeapon FROM weaponkillsbyplayer X, weapon y WHERE x.MatchID=@MatchID AND x.weapon=y.weapon GROUP BY y.category3) b, weapon c
WHERE a.weapon=c.Weapon AND c.Category3=b.category3 AND a.kills=b.MaxKillsByWeapon AND a.MatchID=@MatchID
ORDER BY a.kills DESC,b.category3 ASC LIMIT 15;

#******************************************************************************************************************************#
# R6 - Infantry - Player & WEAPON Match results: AUTOMATIC

#s1: Player by weapon MP40/STG44/FG42 (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Automatic' AND y.Side1='Axis'
ORDER BY x.kills DESC LIMIT 15;

#s2: Player by weapon THOMPSON/BAR/M3 (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Automatic' AND y.Side1='Allies'
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R7 - Infantry - Player & WEAPON Match results: SEMI ('GEWEHR 43','M1 GARAND','SVT40','M97 TRENCH GUN','M1 CARBINE')

#s1: Player by weapon GEWEHR 43 (top 15)
SELECT x.player,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Semi' AND y.Weapon IN ('GEWEHR 43')
ORDER BY x.kills DESC LIMIT 15;

#s2: Player by weapon M1 GARAND/SVT40 (top 15)
SELECT x.player,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Semi' AND y.Weapon IN ('M1 GARAND','SVT40')
ORDER BY x.kills DESC LIMIT 15;

#s3: Player by weapon M1 CARBINE/ETC (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Semi' AND y.Weapon IN ('M97 TRENCH GUN','M1 CARBINE')
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R8 - Infantry - Player & WEAPON Match results: BOLT/PISTOL/MG

#s1: Player by weapon BOLT (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Bolt'
ORDER BY x.kills DESC LIMIT 15;

#s2: Player by weapon PISTOL (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Firearm' AND y.Category3='Pistol'
ORDER BY x.kills DESC LIMIT 15;

#s3: Player by weapon MG (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='MG'
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R9 - Infantry - Player & WEAPON Match results: EXPLOSIVES

#s1: Player by weapon AT ROCKET LAUNCHER (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='AT' AND y.Category3='AT rocket launcher'
ORDER BY x.kills DESC LIMIT 15;

#s2: Player by weapon GRENADE (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Explosive' AND y.Category3='Grenade'
ORDER BY x.kills DESC LIMIT 15;

#s3: Player by weapon SATCHEL/MINE AP/AT (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND ((y.Category2='Explosive' AND y.Category3 NOT IN ('AT rocket launcher','Grenade')) OR y.Category2='Mine')
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R10 - Infantry - Player & WEAPON Match results: Melee and others

#s1: Player by weapon MELEE (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='Melee'
ORDER BY x.kills DESC LIMIT 15;

#s2: Player by weapon AT GUN (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2='AT GUN'
ORDER BY x.kills DESC LIMIT 15;

#s3: Player by weapon OTHERS (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Infantry' AND y.Category2 NOT IN ('MG','Mine','Melee','AT GUN') AND y.Category3 NOT IN ('Automatic','Bolt','Pistol','AT rocket launcher','Grenade') AND y.weapon NOT IN ('GEWEHR 43','M1 GARAND','SVT40','M97 TRENCH GUN','M1 CARBINE','SATCHEL')
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R11 - Recon & artillery - Player & WEAPON Match results

#s1: RECON (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Recon'
ORDER BY x.kills DESC LIMIT 15;

#s2: ARTILLERY (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Artillery'
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R12 - TANK - Player & WEAPON Match results

#s1: TANK CANNON (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category3='Tank cannon'
ORDER BY x.kills DESC LIMIT 15;

#s2: TANK MG (top 15)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category3='Tank MG'
ORDER BY x.kills DESC LIMIT 15;

#******************************************************************************************************************************#
# R13 - TANK - Player & WEAPON Match results: TYPE

#s1: TANK HEAVY (top 6)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category2='Heavy tank'
ORDER BY x.kills DESC LIMIT 6;

#s2: TANK MEDIUM (top 6)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category2='Medium tank'
ORDER BY x.kills DESC LIMIT 6;

#s3: TANK LIGHT (top 6)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category2='Light tank'
ORDER BY x.kills DESC LIMIT 6;

#s4: TANK RECON (top 6)
SELECT x.player,x.weapon,x.kills FROM weaponkillsbyplayer X, weapon Y WHERE x.MatchID=@MatchID AND x.Weapon=y.Weapon AND y.Category1='Tank' AND y.Category2='Recon tank'
ORDER BY x.kills DESC LIMIT 6;

#******************************************************************************************************************************#
# R14 - SQUADS performance report

#s1: Infantry squads deaths
SET @squadRole='Infantry';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s2: Attack squads deaths
SET @squadRole='Attack';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s3: Defense squads deaths
SET @squadRole='Defense';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s4: Armored squads deaths
SET @squadRole='Armored';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s5: Recon squads deaths
SET @squadRole='Recon';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s6: Commander deaths
SET @squadRole='Commander';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s7: Artillery squads deaths
SET @squadRole='Artillery';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

#s8: Artillery defense squads deaths
SET @squadRole='Artillery defense';
SELECT b.SquadRole AS 'Role',d.SquadRole AS 'Killer_Role',
sum(CASE WHEN a.PlayerSide=1 then c.Deaths ELSE 0 END) 'Allies',
sum(CASE WHEN a.PlayerSide=2 then c.Deaths ELSE 0 END) 'Axis',
SUM(c.Deaths) 'Total'
FROM playerstats a, matchsquads b, deathsbyplayer c, matchsquads d
WHERE
a.MatchID=@MatchID AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.SquadRole=@SquadRole AND a.MatchID=c.MatchID AND a.Player=c.Victim AND c.Killer=d.Player AND a.MatchID=d.MatchID
GROUP BY b.SquadRole,d.SquadRole
ORDER BY b.SquadRole,d.SquadRole;

