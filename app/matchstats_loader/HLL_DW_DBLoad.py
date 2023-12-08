import logging
import json
import HLL_DW_error
import datetime
import HLL_DW_GetConfig
import db_modules.HLL_db_mariadb as HLLdb

def sqlInsertMatch(dbcursor,matchInfofromCSV,matchStatsInfofromURL,matchInfofromJSON):
    """Insert a new match in database and returns the internal database match ID

    Args:
        dbcursor (_type_): _description_
        matchInfofromCSV (_type_): _description_
        matchStatsInfofromURL (_type_): _description_
        matchInfofromJSON (_type_): _description_

    Raises:
        Exception: mapID not found in table map for mapkey
        Exception: matchDbID not found in table gamematch or several results found
        Exception: Error trying to insert new match into database table gamematch: match exists for CMID

    Returns:
        int: -1 if error; >0 new matchDbID
    """

    # Get database mapID from table map throught matchInfofromJSON["RCONMapName"]
    mapID=0
    strsql="SELECT mapID from map where MapKey='%s'" % matchInfofromJSON["RCONMapName"]
    try:
        ret=HLLdb.sqlExecute(dbcursor,strsql)
        if ret==1:
            mapID=int(dbcursor.fetchone()[0])
        else:
            raise Exception("mapID not found in table map for mapkey=" + str(matchInfofromJSON["RCONMapName"]) + " or several results found")
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertMatch 1",str(ex.args),str(type(ex)),"Error searching mapID from MapKey in SQL sentence >> (( " + strsql + " )) for array (( " + str(matchInfofromJSON)+" ))")
        return -1

    # Check if CMID+RCONMatchID exists in database (table Gamematch) and insert new DW database match if doesn't exist
    strsql="SELECT 1 from gamematch where CMID=%s AND RCONMatchID=%s" % (matchInfofromCSV["CMID"],matchInfofromJSON["RCONMatchID"])
    try:
        ret=HLLdb.sqlExecute(dbcursor,strsql)
        if ret==0:
            #strsql="INSERT INTO gamematch (CMID, RCONMatchID, MatchName, MatchDesc, ClansCoAllies, ClansCoAxis, StartTime, EndTime, DurationSec, RCONMapName, RCONServerNumber, StatsUrl, JSONStatsURL, GameServerName, GameServerIP, GameServerOwner, MapID, ResultAllies, ResultAxis, MatchType, CompetitionID) VALUES \
            #    (%s,%s,'%s','%s','%s','%s','%s','%s',%s,'%s','%s','%s','%s','%s','%s','%s','%s','%s',%s,%s,%s%s,%s)" \
            #    % (matchInfofromCSV["CMID"],matchInfofromJSON["RCONMatchID"],matchInfofromCSV["MatchName"],matchInfofromCSV["MatchDesc"],matchInfofromCSV["ClansCoAllies"],matchInfofromCSV["ClansCoAxis"],matchInfofromJSON["StartTime"],matchInfofromJSON["EndTime"],matchInfofromJSON["DurationSec"],matchInfofromJSON["RCONMapName"],matchInfofromJSON["RCONServerNumber"],matchInfofromCSV["StatsUrl"],matchStatsInfofromURL["url"],matchInfofromCSV["GameServerName"],matchInfofromCSV["GameServerIP"],matchInfofromCSV["GameServerOwner"],mapID,matchInfofromCSV["MatchType"],matchInfofromCSV["CompetitionID"])

            strsql=f"INSERT INTO gamematch (CMID, RCONMatchID, MatchName, MatchDesc, ClansCoAllies, ClansCoAxis, StartTime, EndTime, DurationSec, RCONMapName, RCONServerNumber, StatsUrl,\
                  JSONStatsURL, GameServerName, GameServerIP, GameServerOwner, MapID, ResultAllies, ResultAxis, MatchType, CompetitionID) VALUES \
                ({matchInfofromCSV['CMID']},{matchInfofromJSON['RCONMatchID']},'{matchInfofromCSV['MatchName']}',\
                '{matchInfofromCSV['MatchDesc']}','{matchInfofromCSV['ClansCoAllies']}','{matchInfofromCSV['ClansCoAxis']}',\
                '{matchInfofromJSON['StartTime']}','{matchInfofromJSON['EndTime']}',{matchInfofromJSON['DurationSec']},\
                '{matchInfofromJSON['RCONMapName']}',{matchInfofromJSON['RCONServerNumber']},'{matchInfofromCSV['StatsUrl']}',\
                '{matchStatsInfofromURL['url']}','{matchInfofromCSV['GameServerName']}','{matchInfofromCSV['GameServerIP']}','{matchInfofromCSV['GameServerOwner']}',\
                {str(mapID)},{matchInfofromCSV['ResultAllies']},{matchInfofromCSV['ResultAxis']},{matchInfofromCSV['MatchType']},{matchInfofromCSV['CompetitionID']});"
            
            if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)

            #Get the new created match internal database ID
            strsql="SELECT matchID from gamematch where CMID=%s AND RCONMatchID=%s AND StartTime='%s' AND EndTime='%s'" % (matchInfofromCSV["CMID"],matchInfofromJSON["RCONMatchID"],matchInfofromJSON["StartTime"],matchInfofromJSON["EndTime"])
            if HLL_DW_GetConfig.runParams["cTest"]==0:
                ret=HLLdb.sqlExecute(dbcursor,strsql)
                if ret==1:
                    matchDbID=int(dbcursor.fetchone()[0])
                    return matchDbID
                else:
                    raise Exception("matchDbID not found in table gamematch or several results found for " + str(matchInfofromCSV) + " " + str(matchInfofromJSON))
            else:
                return 1

        else:
            raise Exception("Error trying to insert new match into database table gamematch: match exists for CMID=" + str(matchInfofromCSV["CMID"]) + " and RCONMatchID=" + matchInfofromJSON["RCONMatchID"])
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertMatch 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(matchInfofromJSON) + " ))")
        return -1

def sqlCheckNotRegisteredWeapons(dbcursor,MatchDbID,matchInfofromCSV,matchStatsInfofromURL):
    """Check match stat weapons not registered in database table weapon and log/raise the error

    Args:
        dbcursor (cursor): opened cursor to database
        MatchDbID (int): Match internal database ID for player stats

    Returns:
        int: 0 if no errors; -1 if any error
    """
    strsql=f"SELECT DISTINCT Weapon FROM weaponkillsbyplayer a WHERE a.matchID={MatchDbID} AND a.weapon NOT IN (SELECT DISTINCT weapon FROM weapon);"
    try:        
        ret=HLLdb.sqlExecute(dbcursor,strsql)
        if ret==0:
            return 0
        else:
            for strweapon in dbcursor.fetchall():
                logging.error(f"Weapon '{strweapon}' not found in database table weapon")
            HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckNotRegisteredWeapons 1","","","Error: Match stats contains weapons not registered in database. See log file to get the new weapons that must be loaded into table weapon before load this match CMID = " + matchInfofromCSV["CMID"] + ", map_id = " + matchStatsInfofromURL["RCONmatchIDfromUrl"])
            return -1

    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckNotRegisteredWeapons 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
        return -1


def sqlCheckOrInsertPlayer(dbcursor,playerStats):
    """Check if SteamID exists in database (table Player) and insert new DW database player if doesn't exist.
    Insert new player nicks into database

    Args:
        dbcursor (cursor): opened cursor to database
        playerStats (str): JSON with player stats to be inserted in database

    Returns:
        int: 0 if exists or inserted new; -1 if error
    """

    strsql="SELECT 1 from Player where DWPlayerID='%s'" % playerStats["DWPlayerID"]
    try:        
        ret=HLLdb.sqlExecute(dbcursor,strsql)
        if ret==0:
            strsql="insert into Player (DWPlayerID,SteamID,Rank) values ('%s','%s',%s)" % (playerStats["DWPlayerID"],playerStats["SteamID"],"0")
            if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)

            strsql="insert into PlayerNicks (SteamID,PlayerNick,MainNick) values ('%s','%s',1)" % (playerStats["SteamID"],HLLdb.sqlEscape(playerStats["Player"]))
            if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        else:
            strsql=f"SELECT 1 from PlayerNicks WHERE SteamID='{playerStats['SteamID']}' AND PlayerNick='{HLLdb.sqlEscape(playerStats['Player'])}'"
            ret=HLLdb.sqlExecute(dbcursor,strsql)
            if ret==0:
                strsql="insert into PlayerNicks (SteamID,PlayerNick,MainNick) values ('%s','%s',0)" % (playerStats["SteamID"],HLLdb.sqlEscape(playerStats["Player"]))
                if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertPlayer 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(playerStats) + " ))")
        return -1

def sqlFillPlayerClanAndTAG (dbcursor,MatchDbID):
    """Fill table field playerstats.playerclantag and playerstats.playerclanID based on clan TAG found in player nick name in the match

    Args:
        dbcursor (cursor): opened cursor to database
        MatchDbID (int): Match internal database ID for player stats

    Returns:
        int: 0 if no errors; -1 if any error
    """
    strsql=f"UPDATE playerstats x, clantag y SET x.PlayerClanTag=y.ClanTag,x.PlayerClanID=y.ClanID where locate(y.clantag,x.Player)>0 AND x.MatchID={MatchDbID};"
    try:
        HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlFillPlayerClanAndTAG 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
        return -1

def sqlFillPlayerMatchSide (dbcursor,MatchDbID):
    """Fill table field playerstats.side based on match kills weapons used by player. If player doesn't have kills but has deaths, set side based on weapondeathsbyplayer. Incoherences may be generated for players changing side in the same match
        Players with no kills and deaths will have PlayerSide as Null
    
    Args:
        dbcursor (cursor): opened cursor to database
        MatchDbID (int): Match internal database ID for player stats

    Returns:
        int: 0 if no errors; -1 if any error
    """
    
    try:        
        strsql=f"UPDATE playerstats a, weaponkillsbyplayer c, weapon d SET a.PlayerSide=d.Side WHERE a.MatchID={MatchDbID} AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0 and c.Kills=(SELECT max(x.Kills) FROM weaponkillsbyplayer x, weapon y WHERE a.Player=x.Player AND a.MatchID=x.MatchID AND x.Weapon=y.Weapon AND y.Side<>0);"
        HLLdb.sqlExecute(dbcursor,strsql)

        # strsql=f"UPDATE playerstats a, weapondeathsbyplayer b, weapon c SET a.PlayerSide = CASE when c.side=1 then 2 when c.side=2 then 1 else 0 end WHERE a.MatchID={MatchDbID} AND a.Kills=0 AND a.Deaths>0 AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.side<>0;"
        # HLLdb.sqlExecute(dbcursor,strsql)

        strsql=f"UPDATE playerstats a, weapondeathsbyplayer b, weapon c SET a.PlayerSide = CASE when c.side=1 then 2 when c.side=2 then 1 else 0 end WHERE a.MatchID={MatchDbID} AND a.PlayerSide IS NULL AND a.MatchID=b.MatchID AND a.Player=b.Player AND b.Weapon=c.Weapon AND c.side<>0 and b.Deaths=(SELECT max(x.deaths) FROM weapondeathsbyplayer x, weapon y WHERE a.Player=x.Player AND a.MatchID=x.MatchID AND x.Weapon=y.Weapon AND y.Side<>0);"
        HLLdb.sqlExecute(dbcursor,strsql)

        strsql=f"UPDATE playerstats a, deathsbyplayer c, playerstats d SET a.PlayerSide=1+(d.PlayerSide MOD 2) WHERE a.Deaths>0 AND a.PlayerSide is null AND a.MatchID={MatchDbID} AND a.MatchID=c.MatchID AND a.Player=c.Victim AND a.MatchID=d.MatchID AND c.Killer=d.Player AND d.PlayerSide<>0 AND d.PlayerSide is not NULL and c.Deaths=(SELECT max(c.Deaths) FROM deathsbyplayer x, PlayerStats y WHERE a.Player=x.Victim AND a.MatchID=x.MatchID AND x.MatchID=y.MatchID AND x.Killer=y.Player AND y.PlayerSide<>0);"
        HLLdb.sqlExecute(dbcursor,strsql)

        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlFillPlayerMatchSide 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
        return -1

def sqlFillMatchRolesAux (MatchDbID,squadRole,weaponCategory1,weaponthreshold,playerRole):
    """Aux function to form SQL string to insert match squad roles to every player

    Args:
        MatchDbID (int): Match database internal ID
        squadRole (string): Role to set to player squad (Commander, Armored, Artillery, Recon)
        weaponCategory1 (string): kill weapon from table field weapon.Category1 made by player
        weaponthreshold (string): Threshold of kills of total kills from player to set the squad role
        playerRole (string): Role to set to player

    Returns:
        string: SQL sentence to insert match squad role
    """

    strsql=f"INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side) \
            SELECT 1,a.Player,a.SteamID,'{squadRole}','{playerRole}','{weaponCategory1}',a.PlayerSide FROM playerstats a, weaponkillsbyplayer b, weapon c \
            WHERE a.MatchID={MatchDbID} AND a.player=b.player AND b.MatchID={MatchDbID} AND b.Weapon=c.Weapon AND c.category1='{weaponCategory1}' \
            GROUP BY a.Player,a.SteamID,'{squadRole}','{playerRole}','{weaponCategory1}',a.PlayerSide HAVING ((SUM(b.Kills)/sum(a.Kills))>={weaponthreshold});"
    return strsql


def sqlFillMatchRoles (dbcursor,MatchDbID):
    """Fill table matchsquads based on match kills weapons used by player. Incoherences may be generated for players changing side in the same match.
        Players with no kills won't have matchrole
    
    Args:
        dbcursor (cursor): opened cursor to database
        MatchDbID (int): Match internal database ID for player stats

    Returns:
        int: 0 if no errors; -1 if any error
    """
    
    try:
        #Fill Commanders role (players with at least 1 kill made by commander category weapon)
        weaponthreshold="0"
        squadRole="Commander"
        weaponCategory1="Commander"
        playerRole="Commander"
        strsql=sqlFillMatchRolesAux(MatchDbID,squadRole,weaponCategory1,weaponthreshold,playerRole)
        HLLdb.sqlExecute(dbcursor,strsql)

        #Fill Armored role (players with at least 20% of theirs kills are made by tank weapons)
        weaponthreshold="0.20"
        squadRole="Armored"
        weaponCategory1="Tank"
        playerRole="Tank-crew"
        strsql=sqlFillMatchRolesAux(MatchDbID,squadRole,weaponCategory1,weaponthreshold,playerRole)
        HLLdb.sqlExecute(dbcursor,strsql)

        #Fill Artillery role (players with at least 30% of theirs kills are made by artillery weapons)
        weaponthreshold="0.30"
        squadRole="Artillery"
        weaponCategory1="Artillery"
        playerRole="Artilleryman"
        strsql=sqlFillMatchRolesAux(MatchDbID,squadRole,weaponCategory1,weaponthreshold,playerRole)
        HLLdb.sqlExecute(dbcursor,strsql)

        #Fill Sniper role (players with at least 50% of theirs kills are made by sniper weapons)
        weaponthreshold="0.50"
        squadRole="Recon"
        weaponCategory1="Recon"
        playerRole="Sniper"
        strsql=sqlFillMatchRolesAux(MatchDbID,squadRole,weaponCategory1,weaponthreshold,playerRole)
        HLLdb.sqlExecute(dbcursor,strsql)

        #Set squad type as Infantry to rest of players in that match
        strsql=f"INSERT INTO matchsquads (MatchID, Player, SteamID, SquadRole, PlayerRole, SquadName, Side) \
            SELECT DISTINCT {MatchDbID},a.player,a.SteamID,'Infantry','Infantry','Infantry',a.PlayerSide FROM playerstats a \
            WHERE a.MatchID={MatchDbID} AND a.Player not IN (SELECT DISTINCT x.Player FROM matchsquads x WHERE x.MatchID={MatchDbID})"
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)

        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlFillMatchRoles 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
        return -1

def sqlInsertPlayerStats(dbcursor,playerStats):
    """Insert player match stats into database

    Args:
        dbcursor (cursor): opened cursor to database
        playerStats (str): JSON with player stats to be inserted in database

    Returns:
        int: 0 if playerstats inserted; -1 if error
    """

    strsql="INSERT INTO PlayerStats (CMID,MatchID,Player,\
        DWPlayerID,RCONPlayerID,SteamID,\
        Kills,Deaths,TKs,\
        KD,MaxKillStreak,KillsMin,DeathsMin,\
        MaxDeathStreak,MaxTKStreak,DeathByTK,DeathByTKStreak,\
        LongestLifeSec,ShortestLifeSec,MatchActiveTimeSec,\
        Nemesis,Victims,KillsByWeapons,DeathsByWeapons,\
        CombatPoints,OffensePoints,DefensePoints,SupportPoints)\
        VALUES (%s,%s,'%s',\
            '%s',%s,'%s',\
            %s,%s,%s,\
            %s,%s,%s,%s,\
            %s,%s,%s,%s,\
            %s,%s,%s,\
            '%s','%s','%s','%s',\
            %s,%s,%s,%s)"
    strNemesis=HLLdb.sqlEscape(json.dumps(playerStats["Nemesis"]))
    strVictims=HLLdb.sqlEscape(json.dumps(playerStats["Victims"]))
    strKillsByWeapons=HLLdb.sqlEscape(json.dumps(playerStats["KillsByWeapons"]))
    strDeathsByWeapons=HLLdb.sqlEscape(json.dumps(playerStats["DeathsByWeapons"]))

    aSQLValues=(playerStats["CMID"],playerStats["MatchID"],HLLdb.sqlEscape(playerStats["Player"]),\
        playerStats["DWPlayerID"],playerStats["RCONPlayerID"],playerStats["SteamID"],\
        playerStats["Kills"],playerStats["Deaths"],playerStats["TKs"],\
        playerStats["KD"],playerStats["MaxKillStreak"],playerStats["KillsMin"],playerStats["DeathsMin"],\
        playerStats["MaxDeathStreak"],playerStats["MaxTKStreak"],playerStats["DeathByTK"],playerStats["DeathByTKStreak"],\
        playerStats["LongestLifeSec"],playerStats["ShortestLifeSec"],playerStats["MatchActiveTimeSec"],\
        strNemesis,strVictims,strKillsByWeapons,strDeathsByWeapons,\
        playerStats["CombatPoints"],playerStats["OffensePoints"],playerStats["DefensePoints"],playerStats["SupportPoints"])
    strsql=strsql % aSQLValues
    try:        
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertPlayerStats 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(playerStats) + " ))")
        return -1

def sqlInsertNemesisList(dbcursor,nemesisList):

    strsql="INSERT INTO deathsbyplayer (MatchID,Victim,Killer,Deaths) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (nemesisList["MatchID"],HLLdb.sqlEscape(nemesisList["Victim"]),HLLdb.sqlEscape(nemesisList["Killer"]),nemesisList["Deaths"])
    try:
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertNemesisList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(nemesisList))
        return -1

def sqlInsertVictimList(dbcursor,victimList):

    strsql="INSERT INTO killsbyplayer (MatchID,Killer,Victim,Kills) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (victimList["MatchID"],HLLdb.sqlEscape(victimList["Killer"]),HLLdb.sqlEscape(victimList["Victim"]),victimList["Kills"])
    try:
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertVictimList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(victimList))
        return -1

def sqlInsertWeaponKillsList(dbcursor,weaponList):

    strsql="INSERT INTO weaponkillsbyplayer (MatchID,Player,Weapon,Kills) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (weaponList["MatchID"],HLLdb.sqlEscape(weaponList["Player"]),HLLdb.sqlEscape(weaponList["Weapon"]),weaponList["Kills"])
    try:
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertWeaponKillsList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(weaponList) + " ))")
        return -1

def sqlInsertWeaponDeathsList(dbcursor,weaponList):

    strsql="INSERT INTO weapondeathsbyplayer (MatchID,Player,Weapon,Deaths) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (weaponList["MatchID"],HLLdb.sqlEscape(weaponList["Player"]),HLLdb.sqlEscape(weaponList["Weapon"]),weaponList["Deaths"])
    try:
        if HLL_DW_GetConfig.runParams["cTest"]==0: HLLdb.sqlExecute(dbcursor,strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertWeaponDeathsList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(weaponList) + " ))")
        return -1

def sqlPreCheckNumPlayers(dbcursor):

    strsql="SELECT if((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),1,0) AS CheckNumPlayers;"
    try:
        HLLdb.sqlExecute(dbcursor,strsql)
        if dbcursor.fetchone()[0]==1:
            HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlPreCheckNumPlayers 1","","","Warning: pre-checking gobally count distinct SteamID not equal in playerstats and players")
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlPreCheckNumPlayers 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " ))")
        return -1

def sqlCheckMatchNumPlayers(dbcursor,MatchDbID):

    strsql=f"SELECT COUNT(*) AS NumPlayers FROM playerstats WHERE MatchID={MatchDbID} AND NOT EXISTS (SELECT 1 FROM player WHERE player.SteamID=playerstats.SteamID);"
    try:
        if HLLdb.sqlExecute(dbcursor,strsql):
            NumPlayers=dbcursor.fetchone()[0]
            if NumPlayers>=1:
                HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckMatchNumPlayers 1","","","Warning: not all match players exists in table player for matchID = " + str(MatchDbID))
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckMatchNumPlayers 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " ))")
        return -1

def sqlCheckConsistency(strsql,dbcursor,strerror):

    try:
        HLLdb.sqlExecute(dbcursor,strsql)
        if dbcursor.fetchone()[0]>0:
            HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckConsistency 1","","",strerror)
            return -1
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlCheckConsistency 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " ))")
        return -1


def sqlCheckKillsAndDeathsSumConsistency(dbcursor,MatchDbID):

    strsql=f"SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID={MatchDbID})<>(SELECT SUM(deaths) FROM deathsbyplayer WHERE MatchID={MatchDbID}),1,0) AS DiffKill_Deaths;"
    sqlCheckConsistency(strsql,dbcursor,"Warning1: checking sum kills in killsbyplayer-deathsbyplayer for match = " + str(MatchDbID))
    
    strsql=f"SELECT if((SELECT SUM(Kills) FROM killsbyplayer WHERE MatchID={MatchDbID})<>(SELECT SUM(kills) FROM weaponkillsbyplayer WHERE MatchID={MatchDbID}),1,0) AS DiffKill_Kills;"
    sqlCheckConsistency(strsql,dbcursor,"Warning2: checking sum kills in killsbyplayer-weaponkillsbyplayer for match = " + str(MatchDbID))

    strsql=f"SELECT if((SELECT SUM(Kills) FROM playerstats WHERE MatchID={MatchDbID})<>(SELECT SUM(kills) FROM killsbyplayer WHERE MatchID={MatchDbID}),1,0) AS DiffKill_Deaths;"
    sqlCheckConsistency(strsql,dbcursor,"Warning3: checking sum kills in playerstats-killsbyplayer for match = " + str(MatchDbID))

    strsql=f"SELECT if((SELECT SUM(Kills) FROM playerstats WHERE MatchID={MatchDbID})<>(SELECT SUM(deaths) FROM playerstats WHERE MatchID={MatchDbID}),1,0) AS DiffKill_Deaths;"
    sqlCheckConsistency(strsql,dbcursor,"Warning4: checking sum kills in playerstats matches sum deaths in playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID={MatchDbID} AND killer NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning5: checking consistency players (killers) in killsbyplayer-playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM killsbyplayer WHERE matchID={MatchDbID} AND victim NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning6: checking consistency players (victims) in killsbyplayer-playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID={MatchDbID} AND victim NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning7: checking consistency victim players in deathsbyplayer-playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM deathsbyplayer WHERE matchID={MatchDbID} AND killer NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning8: checking consistency killer players in deathsbyplayer-playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM weaponkillsbyplayer WHERE matchID={MatchDbID} AND player NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning9: checking consistency players in weaponkillsbyplayer-playerstats for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID={MatchDbID} AND kills>0 AND player NOT IN (SELECT player FROM killsbyplayer WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning10: checking consistency players in playerstats-killsbyplayer for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID={MatchDbID} AND Deaths>0 AND player NOT IN (SELECT player FROM deathsbyplayer WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning11: checking consistency players in playerstats-deathsbyplayer for match = " + str(MatchDbID))

    strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM playerstats WHERE matchID={MatchDbID} AND kills>0 AND player NOT IN (SELECT player FROM weaponkillsbyplayer WHERE matchID={MatchDbID});"
    sqlCheckConsistency(strsql,dbcursor,"Warning12: checking consistency players in playerstats-weaponkillsbyplayer for match = " + str(MatchDbID))

    strsql=f"SELECT count(*) FROM playerstats WHERE SteamID='0' AND matchID={MatchDbID};"
    sqlCheckConsistency(strsql,dbcursor,"Warning13: checking playerstat, found players with steamID=0 for match = " + str(MatchDbID))

    # Disabled to avoid Warning:s when loading old matches that don't have JSON weapondeathsbyplayer field
    #strsql=f"SELECT COUNT(*) AS HitsNotRegistered FROM weapondeathsbyplayer WHERE matchID={MatchDbID} AND player NOT IN (SELECT player FROM playerstats WHERE matchID={MatchDbID});"
    #sqlCheckConsistency(strsql,dbcursor,"Warning14: checking consistency players in weapondeathsbyplayer-playerstats for match = " + str(MatchDbID))


def dbLoadNemesisList (MatchDbID,player,jsonNemesisList,dbcursor):

    iOK=0
    try:
        nemesisList = {"MatchID": "", "Victim": "", "Killer": "", "Deaths": ""}
        for jsonNemesisItem in jsonNemesisList:
            nemesisList["MatchID"]=str(MatchDbID)
            nemesisList["Victim"]=player
            nemesisList["Killer"]=str(jsonNemesisItem)
            nemesisList["Deaths"]=str(jsonNemesisList[jsonNemesisItem])
            iOK+=sqlInsertNemesisList(dbcursor,nemesisList)
        return iOK
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py loadNemesisList 1",str(ex.args),str(type(ex)),"Error extracting Nemesis JSON Match ID = " + str(MatchDbID) + " Player = (( " + player + " )) >> NemesisList >> ( " + json.dumps(jsonNemesisList) + " )" )
        return iOK-1

def dbLoadVictimList (MatchDbID,player,jsonVictimList,dbcursor):

    iOK=0
    try:
        victimList = {"MatchID": "", "Killer": "", "Victim": "", "Kills": ""}
        for jsonVictimItem in jsonVictimList:
            victimList["MatchID"]=str(MatchDbID)
            victimList["Killer"]=player
            victimList["Victim"]=str(jsonVictimItem)
            victimList["Kills"]=str(jsonVictimList[jsonVictimItem])
            iOK+=sqlInsertVictimList(dbcursor,victimList)
        return iOK
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py loadVictimList 1",str(ex.args),str(type(ex)),"Error extracting Victim JSON Match ID = " + str(MatchDbID) + " Player = (( " + player + " )) >> VictimList >> ( " + json.dumps(jsonVictimList) + " )" )
        return iOK+1

def dbLoadWeaponKillsList (MatchDbID,player,jsonWeaponList,dbcursor):

    iOK=0
    try:
        weaponList = {"MatchID": "", "Player": "", "Weapon": "", "Kills": ""}
        for jsonWeaponItem in jsonWeaponList:
            weaponList["MatchID"]=str(MatchDbID)
            weaponList["Player"]=player
            weaponList["Weapon"]=str(jsonWeaponItem)
            weaponList["Kills"]=str(jsonWeaponList[jsonWeaponItem])
            iOK+=sqlInsertWeaponKillsList(dbcursor,weaponList)
        return iOK
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py loadWeaponKillsList 1",str(ex.args),str(type(ex)),"Error extracting weapon kills JSON Match ID = " + str(MatchDbID) + " Player = (( " + player + " )) >> WeaponList >> ( " + json.dumps(jsonWeaponList) + " )")
        return iOK-1

def dbLoadWeaponDeathsList (MatchDbID,player,jsonWeaponList,dbcursor):

    iOK=0
    try:
        weaponList = {"MatchID": "", "Player": "", "Weapon": "", "Deaths": ""}
        for jsonWeaponItem in jsonWeaponList:
            weaponList["MatchID"]=str(MatchDbID)
            weaponList["Player"]=player
            weaponList["Weapon"]=str(jsonWeaponItem)
            weaponList["Deaths"]=str(jsonWeaponList[jsonWeaponItem])
            iOK+=sqlInsertWeaponDeathsList(dbcursor,weaponList)
        return iOK
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py loadWeaponDeathsList 1",str(ex.args),str(type(ex)),"Error extracting weapon deaths JSON Match ID = " + str(MatchDbID) + " Player = (( " + player + " )) >> WeaponList >> (" + json.dumps(jsonWeaponList) + ")")
        return iOK-1

def dbLoadPlayerStats (matchInfofromCSV,MatchDbID,strMatchJSON,dbcursor):

    #TODO Hay que adaptar a los nuevos parámetros de entrada matchInfofromCSV[]

    iOK=0
    try:
        jsonStats = json.loads(strMatchJSON)

        playerStats = {"MatchName": "", "CMID": "", "MatchID": "", "Player": "", "DWPlayerID": "", "RCONPlayerID": "", "SteamID": "", "Kills": "", "Deaths": "", "TKs": "", "KD": "", "MaxKillStreak": "", "KillsMin": "", \
            "DeathsMin": "", "MaxDeathStreak": "", "MaxTKStreak": "", "DeathByTK": "", "DeathByTKStreak": "", "LongestLifeSec": "", "ShortestLifeSec": "", \
            "MatchActiveTimeSec": "", "Nemesis": "", "Victims": "", "KillsByWeapons": "", "DeathsByWeapons": "", "CombatPoints" : "", "OffensePoints" : "", "DefensePoints" : "", "SupportPoints" : ""}

        strjsonStats = "ALL Match JSON"

        for jsonPlayerStats in jsonStats["result"]["player_stats"]:
            strjsonStats = str(jsonPlayerStats)
            playerStats["MatchName"]=str(matchInfofromCSV["MatchName"])
            playerStats["CMID"]=str(matchInfofromCSV["CMID"])
            playerStats["MatchID"]=str(MatchDbID)

            playerStats["RCONPlayerID"]=str(jsonPlayerStats["player_id"])

            # Check existing SteamID in JSON or set to "0" if not exists
            strCheckedSteamID=""
            try:
                strCheckedSteamID=str(jsonPlayerStats["steaminfo"]["profile"]["steamid"])
            except:
                try:
                    strCheckedSteamID=str(jsonPlayerStats["steam_id_64"])
                except:
                    strCheckedSteamID="0"

            # Set internal DW database player ID as SteamID if checked and is valid OR set to number concat from CMID and RCONPlayerID
            strDWPlayerID=""
            if strCheckedSteamID!="0" and strCheckedSteamID.isnumeric():
                strDWPlayerID=strCheckedSteamID
            else:
                strDWPlayerID=str(playerStats["CMID"]) + str(playerStats["RCONPlayerID"])

            playerStats["DWPlayerID"]=strDWPlayerID
            playerStats["SteamID"]=strDWPlayerID # If strCheckedSteamID is valid (number <> 0) it will be assigned the valid Steam ID, but if not is valid, it will be set to a number that identifies the player by an unambiguous way
            # Set the two DWPlayerID and SteamID as equal values to preserve DWPlayerID from future database bulk updates to set known later on valid Steam IDs

            playerStats["Player"]=str(jsonPlayerStats["player"])
            playerStats["Kills"]=str(jsonPlayerStats["kills"])
            playerStats["Deaths"]=str(jsonPlayerStats["deaths"])
            try:
                playerStats["TKs"]=str(jsonPlayerStats["teamkills"])
            except:
                playerStats["TKs"]="0"
            playerStats["KD"]=str(jsonPlayerStats["kill_death_ratio"])
            playerStats["MaxKillStreak"]=str(jsonPlayerStats["kills_streak"])
            playerStats["KillsMin"]=str(jsonPlayerStats["kills_per_minute"])
            playerStats["DeathsMin"]=str(jsonPlayerStats["deaths_per_minute"])
            playerStats["MaxDeathStreak"]=str(jsonPlayerStats["deaths_without_kill_streak"])
            playerStats["MaxTKStreak"]=str(jsonPlayerStats["teamkills_streak"])
            playerStats["DeathByTK"]=str(jsonPlayerStats["deaths_by_tk"])
            playerStats["DeathByTKStreak"]=str(jsonPlayerStats["deaths_by_tk_streak"])
            playerStats["LongestLifeSec"]=str(jsonPlayerStats["longest_life_secs"])
            playerStats["ShortestLifeSec"]=str(jsonPlayerStats["shortest_life_secs"])
            try:
                playerStats["MatchActiveTimeSec"]=str(jsonPlayerStats["time_seconds"])
            except:
                playerStats["MatchActiveTimeSec"]="0"
            playerStats["Nemesis"]=jsonPlayerStats["death_by"]
            playerStats["Victims"]=jsonPlayerStats["most_killed"]
            playerStats["KillsByWeapons"]=jsonPlayerStats["weapons"]
            try:
                # Try to get new fields from new RCON app version or set to 0 if invoquing RCON app version is old
                playerStats["DeathsByWeapons"]="" if str(jsonPlayerStats["death_by_weapons"]) == "None" else jsonPlayerStats["death_by_weapons"]
            except:
                playerStats["DeathsByWeapons"]=""
            
            try:
                # Try to get new fields from new RCON app version or set to 0 if invoquing RCON app version is old
                playerStats["CombatPoints"]=str(int(jsonPlayerStats["combat"] or 0))
                playerStats["OffensePoints"]=str(int(jsonPlayerStats["offense"] or 0))
                playerStats["DefensePoints"]=str(int(jsonPlayerStats["defense"] or 0))
                playerStats["SupportPoints"]=str(int(jsonPlayerStats["support"] or 0))          
            except:
                playerStats["CombatPoints"]="0"
                playerStats["OffensePoints"]="0"
                playerStats["DefensePoints"]="0"
                playerStats["SupportPoints"]="0"

            iOK+=sqlCheckOrInsertPlayer(dbcursor,playerStats)
            iOK+=sqlInsertPlayerStats(dbcursor,playerStats)
            if iOK==0:
                dbLoadNemesisList (MatchDbID,playerStats["Player"],playerStats["Nemesis"],dbcursor)
                dbLoadVictimList (MatchDbID,playerStats["Player"],playerStats["Victims"],dbcursor)
                dbLoadWeaponKillsList (MatchDbID,playerStats["Player"],playerStats["KillsByWeapons"],dbcursor)
                dbLoadWeaponDeathsList (MatchDbID,playerStats["Player"],playerStats["DeathsByWeapons"],dbcursor)
        return iOK
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py loadPlayerStats 1",str(ex.args),str(type(ex)),"Error extracting PlayerStats JSON Match ID = " + str(MatchDbID) + " >> Player Stats >> ( " + strjsonStats + " )")
        return iOK-1

def dbInsertNewMatchRecord(matchInfofromCSV,matchStatsInfofromURL,strMatchJSON,dbcursor):
    """Get match info from match stats JSON page and insert new match into database

    Args:
        matchInfofromCSV (_type_): _description_
        matchStatsInfofromURL (_type_): _description_
        strMatchJSON (_type_): _description_
        dbcursor (_type_): _description_

    Raises:
        Exception: _description_

    Returns:
        _type_: _description_
    """

    iOK=0
    try:
        jsonStats = json.loads(strMatchJSON)

        matchInfofromJSON = {"RCONMatchID": "", "CreationTime": "", "StartTime": "", "EndTime": "", "DurationSec": "0", "RCONServerNumber": "", "RCONMapName": ""}

        jsonMatchInfo=jsonStats["result"]
        if jsonStats["result"]:
            matchInfofromJSON["RCONMatchID"]=str(jsonMatchInfo["id"])
            matchInfofromJSON["CreationTime"]=str(jsonMatchInfo["creation_time"])
            matchInfofromJSON["StartTime"]=str(jsonMatchInfo["start"])
            matchInfofromJSON["EndTime"]=str(jsonMatchInfo["end"])
            matchInfofromJSON["RCONServerNumber"]=str(jsonMatchInfo["server_number"])
            matchInfofromJSON["RCONMapName"]=str(jsonMatchInfo["map_name"])

            try:
                matchInfofromJSON["DurationSec"]=(datetime.datetime.strptime(matchInfofromJSON["EndTime"],"%Y-%m-%dT%H:%M:%S")-datetime.datetime.strptime(matchInfofromJSON["StartTime"],"%Y-%m-%dT%H:%M:%S")).seconds
            except Exception as ex:
                HLL_DW_error.log_error("HLL_DW_DBLoad.py dbInsertNewMatchRecord 1",str(ex.args),str(type(ex)),"Error in JSON StartTime/EndTime for match stats content " + str(strMatchJSON[0:2048]))
                return iOK-1

            MatchDbID=sqlInsertMatch(dbcursor,matchInfofromCSV,matchStatsInfofromURL,matchInfofromJSON)
            if MatchDbID>0:
                return MatchDbID
            else:
                iOK+=MatchDbID
                return iOK-1
        else:
            raise Exception("JSON match stats 'result' field invalid: " + strMatchJSON[0:2000])

    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py dbInsertNewMatchRecord 2",str(ex.args),str(type(ex)),"Error loading into database for Match = " + str(matchInfofromCSV) + " " + str(matchStatsInfofromURL))
        return iOK-1

def dwDbOpenDB (hlldwconfig):
    """Open DB connection and cursor for efficient match bulk load

    Args:
        hlldwconfig (dict): ini app config        
    
    Returns:
        dbConn (Object): pymysql connection
        dbcursor (Object): pymysql cursor
        int: -1 if error; 0 if OK
    """

    try:
        dbConn=HLLdb.sqlConnect(hlldwconfig["dbserver"],hlldwconfig["dbuser"],hlldwconfig["dbpass"],hlldwconfig["dbname"],hlldwconfig["dbcharset"],hlldwconfig["dbcollation"])
        dbcursor=HLLdb.sqlOpenCursor(dbConn)

        return dbConn,dbcursor,0

    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py dwDbOpenDB 1",str(ex.args),str(type(ex)),"Error opening database connection and cursor = " + hlldwconfig["dbserver"] + " " + hlldwconfig["dbuser"] + " " + hlldwconfig["dbname"])
        HLLdb.sqlCloseCursor(dbcursor)
        HLLdb.sqlCloseConnection(dbConn)
        return None,None,-1

def dwDbCloseDB (dbConn,dbcursor):
    
    HLLdb.sqlCloseCursor(dbcursor)
    HLLdb.sqlCloseConnection(dbConn)



def dwDbLoadMatchJSON(dbConn,dbcursor,matchInfofromCSV,matchStatsInfofromURL,statsPageBody):
    """Loads a new single match and its stats into DW database and commits if succeed

    Args:
        dbConn (Object): pymysql connection
        dbcursor (Object): pymysql cursor
        matchInfofromCSV (dict): Match info from CSV bulk load file HLL_DW_ETL_list.csv
        matchStatsInfofromURL (dict): Match info from stats URL
        statsPageBody (string): JSON from match stats page

    Returns:
        int: 0 if match is loaded successfully; <0 if error (number of errors found)
    """

    iOK=0
    try:
        #Pre-check if players are registered in database. If not, warns in logging but continues to load match
        sqlPreCheckNumPlayers(dbcursor)
        
        HLLdb.sqlStartTransaction(dbConn)
        MatchDbID=dbInsertNewMatchRecord(matchInfofromCSV,matchStatsInfofromURL,statsPageBody,dbcursor)
        if MatchDbID>0:
            iOK+=dbLoadPlayerStats(matchInfofromCSV,MatchDbID,statsPageBody,dbcursor)
            #Post-check if all players are registered in database. If not, aborts match load but continues batch load for next match
            sqlCheckMatchNumPlayers(dbcursor,MatchDbID)
            #If there are match stats weapons not registered in DW database, aborts match load but continues batch load for next match
            if iOK>=0: iOK+=sqlCheckNotRegisteredWeapons(dbcursor,MatchDbID,matchInfofromCSV,matchStatsInfofromURL)
            if iOK>=0: iOK+=sqlFillPlayerClanAndTAG (dbcursor,MatchDbID)
            if iOK>=0: iOK+=sqlFillPlayerMatchSide (dbcursor,MatchDbID)
            if iOK>=0: iOK+=sqlFillMatchRoles (dbcursor,MatchDbID)
            if iOK<0:
                HLLdb.sqlAbort(dbConn)
            else:
                HLLdb.sqlCommit(dbConn)
                sqlCheckKillsAndDeathsSumConsistency(dbcursor,MatchDbID)
        else:
            HLLdb.sqlAbort(dbConn)
            iOK+=MatchDbID
        return iOK


    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py dwDbLoadJSONFile 1",str(ex.args),str(type(ex)),"Error loading into database for Match ID = " + str(matchInfofromCSV) + "-" + str(matchStatsInfofromURL))
        HLLdb.sqlAbort(dbConn)
        return iOK-1

