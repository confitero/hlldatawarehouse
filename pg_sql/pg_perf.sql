--PERFORMANCE AND PLAN ANALYSIS

--#Variaciones de nicks de jugadores
EXPLAIN ANALYZE SELECT distinct a.DWPlayerID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<>b.Player;
EXPLAIN ANALYZE SELECT distinct a.DWPlayerID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<b.Player;
SELECT count(*) FROM PlayerStats 1.992.041

SELECT name,setting FROM pg_settings WHERE name = 'random_page_cost';

set random_page_cost=1.0;

QUERY PLAN                                                                                                          |
--------------------------------------------------------------------------------------------------------------------+
Unique  (cost=230710.34..10990925.33 rows=198341 width=29)                                                          |
  ->  Nested Loop  (cost=230710.34..8227991.09 rows=552586848 width=29)                                             |
        ->  Gather Merge  (cost=230709.92..461710.58 rows=1983409 width=29)                                         |
              Workers Planned: 2                                                                                    |
              ->  Sort  (cost=229709.89..231775.94 rows=826420 width=29)                                            |
                    Sort Key: a.dwplayerid, a.player                                                                |
                    ->  Parallel Seq Scan on playerstats a  (cost=0.00..128712.20 rows=826420 width=29)             |
        ->  Index Scan using idx_17259_fkplayer_dwplayerid_idx on playerstats b  (cost=0.43..2.84 rows=108 width=29)|
              Index Cond: ((dwplayerid)::text = (a.dwplayerid)::text)                                               |
              Filter: ((a.player)::text <> (player)::text)                                                          |
JIT:                                                                                                                |
  Functions: 8                                                                                                      |
  Options: Inlining true, Optimization true, Expressions true, Deforming true                                       |
  

  --REAL
  
  QUERY PLAN                                                                                                                                                                                          |
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Unique  (cost=1010.65..10580685.97 rows=198341 width=29) (actual time=52.933..200726.812 rows=33400 loops=1)                                                                                        |
  ->  Nested Loop  (cost=1010.65..7817751.73 rows=552586848 width=29) (actual time=52.932..189227.904 rows=263329274 loops=1)                                                                       |
        ->  Gather Merge  (cost=1010.22..420567.23 rows=1983409 width=29) (actual time=52.574..1494.638 rows=1992041 loops=1)                                                                       |
              Workers Planned: 2                                                                                                                                                                    |
              Workers Launched: 2                                                                                                                                                                   |
              ->  Incremental Sort  (cost=10.20..190632.59 rows=826420 width=29) (actual time=39.441..1385.449 rows=664014 loops=3)                                                                 |
                    Sort Key: a.dwplayerid, a.player                                                                                                                                                |
                    Presorted Key: a.dwplayerid                                                                                                                                                     |
                    Full-sort Groups: 3868  Sort Method: quicksort  Average Memory: 27kB  Peak Memory: 27kB                                                                                         |
                    Pre-sorted Groups: 10488  Sort Method: quicksort  Average Memory: 268kB  Peak Memory: 280kB                                                                                     |
                    Worker 0:  Full-sort Groups: 7499  Sort Method: quicksort  Average Memory: 28kB  Peak Memory: 28kB                                                                              |
                      Pre-sorted Groups: 19623  Sort Method: quicksort  Average Memory: 283kB  Peak Memory: 314kB                                                                                   |
                    Worker 1:  Full-sort Groups: 7649  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB                                                                              |
                      Pre-sorted Groups: 19985  Sort Method: quicksort  Average Memory: 305kB  Peak Memory: 334kB                                                                                   |
                    ->  Parallel Index Scan using idx_17259_fkplayer_dwplayerid_idx on playerstats a  (cost=0.43..141213.68 rows=826420 width=29) (actual time=37.454..1221.344 rows=664014 loops=3)|
        ->  Index Scan using idx_17259_fkplayer_dwplayerid_idx on playerstats b  (cost=0.43..2.65 rows=108 width=29) (actual time=0.036..0.087 rows=132 loops=1992041)                              |
              Index Cond: ((dwplayerid)::text = (a.dwplayerid)::text)                                                                                                                               |
              Filter: ((a.player)::text <> (player)::text)                                                                                                                                          |
              Rows Removed by Filter: 312                                                                                                                                                           |
Planning Time: 0.243 ms                                                                                                                                                                             |
JIT:                                                                                                                                                                                                |
  Functions: 13                                                                                                                                                                                     |
  Options: Inlining true, Optimization true, Expressions true, Deforming true                                                                                                                       |
  Timing: Generation 0.462 ms, Inlining 57.350 ms, Optimization 31.433 ms, Emission 23.534 ms, Total 112.779 ms                                                                                     |
Execution Time: 200729.870 ms   -->>>>>>>>>>>>>  200,72987 segundos de ejecución = 3,345 minutos 
  
QUERY PLAN para EXPLAIN ANALYZE SELECT distinct a.DWPlayerID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<>b.Player;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Unique  (cost=0.85..10428890.36 rows=199204 width=29) (actual time=36.557..209696.217 rows=33400 loops=1)                                                                  |
  ->  Nested Loop  (cost=0.85..7641854.64 rows=557407144 width=29) (actual time=36.556..198196.201 rows=263329274 loops=1)                                                 |
        ->  Index Only Scan using ix_playerstats_id_player on playerstats a  (cost=0.43..153251.04 rows=1992041 width=29) (actual time=0.006..909.253 rows=1992041 loops=1)|
              Heap Fetches: 1992041                                                                                                                                        |
        ->  Index Scan using idx_17259_fkplayer_dwplayerid_idx on playerstats b  (cost=0.43..2.67 rows=109 width=29) (actual time=0.038..0.092 rows=132 loops=1992041)     |
              Index Cond: ((dwplayerid)::text = (a.dwplayerid)::text)                                                                                                      |
              Filter: ((a.player)::text <> (player)::text)                                                                                                                 |
              Rows Removed by Filter: 312                                                                                                                                  |
Planning Time: 0.367 ms                                                                                                                                                    |
JIT:                                                                                                                                                                       |
  Functions: 7                                                                                                                                                             |
  Options: Inlining true, Optimization true, Expressions true, Deforming true                                                                                              |
  Timing: Generation 0.308 ms, Inlining 4.336 ms, Optimization 18.820 ms, Emission 13.068 ms, Total 36.531 ms                                                              |
Execution Time: 209698.978 ms                                                                                                                                              |


--SET enable_nestloop = on;

QUERY PLAN para EXPLAIN ANALYZE SELECT distinct a.DWPlayerID,a.Player FROM playerstats a LEFT JOIN playerstats b on a.DWPlayerID=b.DWPlayerID where a.Player<b.Player;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Unique  (cost=0.85..4208728.25 rows=199204 width=29) (actual time=31.738..44854.265 rows=20006 loops=1)                                                                     |
  ->  Nested Loop  (cost=0.85..3279622.85 rows=185821079 width=29) (actual time=31.737..39214.973 rows=131664637 loops=1)                                                   |
        ->  Index Only Scan using ix_playerstats_id_player on playerstats a  (cost=0.43..153251.04 rows=1992041 width=29) (actual time=0.009..2569.376 rows=1992041 loops=1)|
              Heap Fetches: 1992041                                                                                                                                         |
        ->  Index Only Scan using ix_playerstats_id_player on playerstats b  (cost=0.43..1.21 rows=36 width=29) (actual time=0.001..0.015 rows=66 loops=1992041)            |
              Index Cond: ((dwplayerid = (a.dwplayerid)::text) AND (player > (a.player)::text))                                                                             |
              Heap Fetches: 131664637                                                                                                                                       |
Planning Time: 0.308 ms                                                                                                                                                     |
JIT:                                                                                                                                                                        |
  Functions: 5                                                                                                                                                              |
  Options: Inlining true, Optimization true, Expressions true, Deforming true                                                                                               |
  Timing: Generation 0.436 ms, Inlining 4.343 ms, Optimization 15.536 ms, Emission 11.670 ms, Total 31.985 ms                                                               |
Execution Time: 44856.219 ms      




QUERY PLAN para EXPLAIN SELECT COUNT(DISTINCT SteamID) FROM playerstats; 188522
-------------------------------------------------------------------------------+
Aggregate  (cost=137074.51..137074.52 rows=1 width=8)                          |
  ->  Seq Scan on playerstats  (cost=0.00..132094.41 rows=1992041 width=18)    |
JIT:                                                                           |
  Functions: 3                                                                 |
  Options: Inlining false, Optimization false, Expressions true, Deforming true|
  
  

QUERY PLAN para EXPLAIN ANALYZE SELECT COUNT(DISTINCT SteamID) FROM playerstats; 188522
-----------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=137074.51..137074.52 rows=1 width=8) (actual time=1510.117..1510.119 rows=1 loops=1)                        |
  ->  Seq Scan on playerstats  (cost=0.00..132094.41 rows=1992041 width=18) (actual time=0.046..248.726 rows=1992041 loops=1)|
Planning Time: 0.352 ms                                                                                                      |
JIT:                                                                                                                         |
  Functions: 3                                                                                                               |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                                              |
  Timing: Generation 0.111 ms, Inlining 0.000 ms, Optimization 0.133 ms, Emission 2.130 ms, Total 2.374 ms                   |
Execution Time: 1520.164 ms                                                                                                  |

QUERY PLAN para EXPLAIN ANALYZE SELECT COUNT(DISTINCT SteamID) FROM playerstats; 188522
-----------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=137074.51..137074.52 rows=1 width=8) (actual time=1389.515..1389.516 rows=1 loops=1)                        |
  ->  Seq Scan on playerstats  (cost=0.00..132094.41 rows=1992041 width=18) (actual time=0.049..206.523 rows=1992041 loops=1)|
Planning Time: 0.059 ms                                                                                                      |
JIT:                                                                                                                         |
  Functions: 3                                                                                                               |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                                              |
  Timing: Generation 0.142 ms, Inlining 0.000 ms, Optimization 0.128 ms, Emission 1.566 ms, Total 1.836 ms                   |
Execution Time: 1389.696 ms                                                                                                  |

EXPLAIN SELECT count(*) FROM (SELECT count(*) FROM playerstats GROUP BY SteamID) a; 188522
QUERY PLAN                                                                                           |
-----------------------------------------------------------------------------------------------------+
Aggregate  (cost=127899.03..127899.04 rows=1 width=8)                                                |
  ->  Finalize HashAggregate  (cost=127486.94..127670.09 rows=18315 width=26)                        |
        Group Key: playerstats.steamid                                                               |
        ->  Gather  (cost=123549.21..127395.36 rows=36630 width=18)                                  |
              Workers Planned: 2                                                                     |
              ->  Partial HashAggregate  (cost=122549.21..122732.36 rows=18315 width=18)             |
                    Group Key: playerstats.steamid                                                   |
                    ->  Parallel Seq Scan on playerstats  (cost=0.00..120474.17 rows=830017 width=18)|
JIT:                                                                                                 |
  Functions: 7                                                                                       |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                      |
  
EXPLAIN ANALYZE SELECT count(*) FROM (SELECT count(*) FROM playerstats GROUP BY SteamID) a; 188522
QUERY PLAN                                                                                                                                           |
-----------------------------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=127899.03..127899.04 rows=1 width=8) (actual time=362.931..362.964 rows=1 loops=1)                                                  |
  ->  Finalize HashAggregate  (cost=127486.94..127670.09 rows=18315 width=26) (actual time=309.647..357.420 rows=188522 loops=1)                     |
        Group Key: playerstats.steamid                                                                                                               |
        Batches: 21  Memory Usage: 4153kB  Disk Usage: 11048kB                                                                                       |
        ->  Gather  (cost=123549.21..127395.36 rows=36630 width=18) (actual time=224.831..269.781 rows=277863 loops=1)                               |
              Workers Planned: 2                                                                                                                     |
              Workers Launched: 2                                                                                                                    |
              ->  Partial HashAggregate  (cost=122549.21..122732.36 rows=18315 width=18) (actual time=216.239..244.956 rows=92621 loops=3)           |
                    Group Key: playerstats.steamid                                                                                                   |
                    Batches: 5  Memory Usage: 4145kB  Disk Usage: 7760kB                                                                             |
                    Worker 0:  Batches: 5  Memory Usage: 4145kB  Disk Usage: 7856kB                                                                  |
                    Worker 1:  Batches: 5  Memory Usage: 4145kB  Disk Usage: 7664kB                                                                  |
                    ->  Parallel Seq Scan on playerstats  (cost=0.00..120474.17 rows=830017 width=18) (actual time=0.022..78.917 rows=664014 loops=3)|
Planning Time: 0.079 ms                                                                                                                              |
JIT:                                                                                                                                                 |
  Functions: 33                                                                                                                                      |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                                                                      |
  Timing: Generation 0.994 ms, Inlining 0.000 ms, Optimization 0.888 ms, Emission 12.542 ms, Total 14.425 ms                                         |
Execution Time: 364.877 ms                                                                                                                           |

EXPLAIN ANALYZE SELECT CASE	WHEN (SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats) THEN 1	ELSE 0 END
QUERY PLAN                                                                                                                           |
-------------------------------------------------------------------------------------------------------------------------------------+
Result  (cost=141003.06..141003.07 rows=1 width=4) (actual time=1430.637..1430.639 rows=1 loops=1)                                   |
  InitPlan 1 (returns $0)                                                                                                            |
    ->  Aggregate  (cost=3928.53..3928.54 rows=1 width=8) (actual time=47.025..47.026 rows=1 loops=1)                                |
          ->  Seq Scan on player  (cost=0.00..3457.22 rows=188522 width=18) (actual time=0.007..9.055 rows=188522 loops=1)           |
  InitPlan 2 (returns $1)                                                                                                            |
    ->  Aggregate  (cost=137074.51..137074.52 rows=1 width=8) (actual time=1381.019..1381.020 rows=1 loops=1)                        |
          ->  Seq Scan on playerstats  (cost=0.00..132094.41 rows=1992041 width=18) (actual time=0.030..208.313 rows=1992041 loops=1)|
Planning Time: 0.083 ms                                                                                                              |
JIT:                                                                                                                                 |
  Functions: 7                                                                                                                       |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                                                      |
  Timing: Generation 0.224 ms, Inlining 0.000 ms, Optimization 0.140 ms, Emission 2.476 ms, Total 2.841 ms                           |
Execution Time: 1430.918 ms                                                                                                          |

EXPLAIN ANALYZE SELECT CASE	WHEN (SELECT COUNT(*) FROM player)<>(SELECT count(*) FROM (SELECT count(*) FROM playerstats GROUP BY SteamID) a) THEN 1	ELSE 0 END
QUERY PLAN                                                                                                                                                   |
-------------------------------------------------------------------------------------------------------------------------------------------------------------+
Result  (cost=131827.57..131827.58 rows=1 width=4) (actual time=377.381..377.415 rows=1 loops=1)                                                             |
  InitPlan 1 (returns $0)                                                                                                                                    |
    ->  Aggregate  (cost=3928.53..3928.54 rows=1 width=8) (actual time=14.148..14.149 rows=1 loops=1)                                                        |
          ->  Seq Scan on player  (cost=0.00..3457.22 rows=188522 width=0) (actual time=0.007..8.907 rows=188522 loops=1)                                    |
  InitPlan 2 (returns $2)                                                                                                                                    |
    ->  Aggregate  (cost=127899.03..127899.04 rows=1 width=8) (actual time=358.296..358.328 rows=1 loops=1)                                                  |
          ->  Finalize HashAggregate  (cost=127486.94..127670.09 rows=18315 width=26) (actual time=304.971..352.881 rows=188522 loops=1)                     |
                Group Key: playerstats.steamid                                                                                                               |
                Batches: 21  Memory Usage: 4153kB  Disk Usage: 11056kB                                                                                       |
                ->  Gather  (cost=123549.21..127395.36 rows=36630 width=18) (actual time=217.667..263.659 rows=277573 loops=1)                               |
                      Workers Planned: 2                                                                                                                     |
                      Workers Launched: 2                                                                                                                    |
                      ->  Partial HashAggregate  (cost=122549.21..122732.36 rows=18315 width=18) (actual time=209.126..238.355 rows=92524 loops=3)           |
                            Group Key: playerstats.steamid                                                                                                   |
                            Batches: 5  Memory Usage: 4145kB  Disk Usage: 7816kB                                                                             |
                            Worker 0:  Batches: 5  Memory Usage: 4145kB  Disk Usage: 7800kB                                                                  |
                            Worker 1:  Batches: 5  Memory Usage: 4145kB  Disk Usage: 7752kB                                                                  |
                            ->  Parallel Seq Scan on playerstats  (cost=0.00..120474.17 rows=830017 width=18) (actual time=0.024..75.986 rows=664014 loops=3)|
Planning Time: 0.108 ms                                                                                                                                      |
JIT:                                                                                                                                                         |
  Functions: 40                                                                                                                                              |
  Options: Inlining false, Optimization false, Expressions true, Deforming true                                                                              |
  Timing: Generation 1.334 ms, Inlining 0.000 ms, Optimization 0.985 ms, Emission 14.256 ms, Total 16.575 ms                                                 |
Execution Time: 379.358 ms                                                                                                                                   |


EXPLAIN ANALYZE SELECT COUNT(*) AS NumPlayers FROM playerstats WHERE MatchID=1 AND NOT EXISTS (SELECT 1 FROM player WHERE player.SteamID=playerstats.SteamID);
QUERY PLAN                                                                                                                                                          |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=1218.18..1218.19 rows=1 width=8) (actual time=0.312..0.313 rows=1 loops=1)                                                                         |
  ->  Nested Loop Anti Join  (cost=0.85..1218.18 rows=1 width=0) (actual time=0.311..0.311 rows=0 loops=1)                                                          |
        ->  Index Scan using idx_17259_fkplayerresults_gamematch_idx on playerstats  (cost=0.43..19.05 rows=150 width=18) (actual time=0.007..0.023 rows=78 loops=1)|
              Index Cond: (matchid = 1)                                                                                                                             |
        ->  Index Only Scan using idx_17242_ix_player_steamid on player  (cost=0.42..7.98 rows=1 width=18) (actual time=0.003..0.003 rows=1 loops=78)               |
              Index Cond: (steamid = (playerstats.steamid)::text)                                                                                                   |
              Heap Fetches: 78                                                                                                                                      |
Planning Time: 0.185 ms                                                                                                                                             |
Execution Time: 0.333 ms                                                                                                                                            |

EXPLAIN ANALYZE SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID=1 AND kills>0 AND player NOT IN (SELECT player FROM weaponkillsbyplayer WHERE matchID=1);
QUERY PLAN                                                                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=33.25..33.26 rows=1 width=8) (actual time=0.916..0.916 rows=1 loops=1)                                                                                      |
  ->  Index Scan using idx_17259_fkplayerresults_gamematch_idx on playerstats  (cost=13.74..33.11 rows=56 width=0) (actual time=0.915..0.915 rows=0 loops=1)                 |
        Index Cond: (matchid = 1)                                                                                                                                            |
        Filter: ((kills > 0) AND (NOT (hashed SubPlan 1)))                                                                                                                   |
        Rows Removed by Filter: 78                                                                                                                                           |
        SubPlan 1                                                                                                                                                            |
          ->  Index Scan using idx_17287_fkweapinkills_gamematch_idx on weaponkillsbyplayer  (cost=0.43..12.82 rows=194 width=11) (actual time=0.835..0.858 rows=117 loops=1)|
                Index Cond: (matchid = 1)                                                                                                                                    |
Planning Time: 2.042 ms                                                                                                                                                      |
Execution Time: 0.943 ms                                                                                                                                                     |