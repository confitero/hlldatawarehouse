import pymysql
import logging
import json
import HLL_DW_error
import datetime

# Isolated pymysql calls to able future changes to other modules or rdbms

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset):
    dbconn = pymysql.connect(host=phost,user=puser,password=ppassword,database=pdatabase,charset=pcharset)
    return dbconn

def sqlCommit (dbconn):
    dbconn.commit()

def sqlCloseConnection (dbconn):
    dbconn.close()

def sqlOpenCursor(dbconn):
    return dbconn.cursor()

def sqlCloseCursor(dbcursor):
    dbcursor.close()

def sqlExecute(dbcursor,strsql):
    ret=dbcursor.execute(strsql)
    return ret

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
        ret=sqlExecute(dbcursor,strsql)
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
        ret=sqlExecute(dbcursor,strsql)
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
            sqlExecute(dbcursor,strsql)
            
            #Get the new created match internal database ID
            strsql="SELECT matchID from gamematch where CMID=%s AND RCONMatchID=%s AND StartTime='%s' AND EndTime='%s'" % (matchInfofromCSV["CMID"],matchInfofromJSON["RCONMatchID"],matchInfofromJSON["StartTime"],matchInfofromJSON["EndTime"])
            ret=sqlExecute(dbcursor,strsql)
            if ret==1:
                matchDbID=int(dbcursor.fetchone()[0])
                return matchDbID
            else:
                raise Exception("matchDbID not found in table gamematch or several results found for " + str(matchInfofromCSV) + " " + str(matchInfofromJSON))
            
        else:
            raise Exception("Error trying to insert new match into database table gamematch: match exists for CMID=" + str(matchInfofromCSV["CMID"]) + " and RCONMatchID=" + matchInfofromJSON["RCONMatchID"])
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertMatch 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(matchInfofromJSON) + " ))")
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
        ret=dbcursor.execute(strsql)
        if ret==0:
            strsql="insert into Player (DWPlayerID,SteamID,Rank) values ('%s','%s',%s)" % (playerStats["DWPlayerID"],playerStats["SteamID"],"0")
            dbcursor.execute(strsql)

            strsql="insert into PlayerNicks (SteamID,PlayerNick,MainNick) values ('%s','%s',1)" % (playerStats["SteamID"],pymysql.converters.escape_string(playerStats["Player"]))
            dbcursor.execute(strsql)
        else:
            strsql=f"SELECT 1 from PlayerNicks WHERE SteamID='{playerStats['SteamID']}' AND PlayerNick='{pymysql.converters.escape_string(playerStats['Player'])}'"
            ret=dbcursor.execute(strsql)
            if ret==0:
                strsql="insert into PlayerNicks (SteamID,PlayerNick,MainNick) values ('%s','%s',0)" % (playerStats["SteamID"],pymysql.converters.escape_string(playerStats["Player"]))
                dbcursor.execute(strsql)
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
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlFillPlayerClanAndTAG 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
        return -1

def sqlFillPlayerMatchSide (dbcursor,MatchDbID):
    """Fill table field playerstats.side based on match kills weapons used by player

    Args:
        dbcursor (cursor): opened cursor to database
        MatchDbID (int): Match internal database ID for player stats

    Returns:
        int: 0 if no errors; -1 if any error
    """

    strsql=f"UPDATE playerstats a, gamematch b, weaponkillsbyplayer c, weapon d SET a.PlayerSide=d.Side WHERE a.MatchID={MatchDbID} AND a.MatchID=b.MatchID AND a.MatchID=c.MatchID AND a.Player=c.Player AND c.Weapon=d.Weapon AND d.side<>0;"
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlFillPlayerMatchSide 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for internal database match " + str(MatchDbID))
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
    strNemesis=pymysql.converters.escape_string(json.dumps(playerStats["Nemesis"]))
    strVictims=pymysql.converters.escape_string(json.dumps(playerStats["Victims"]))
    strKillsByWeapons=pymysql.converters.escape_string(json.dumps(playerStats["KillsByWeapons"]))
    strDeathsByWeapons=pymysql.converters.escape_string(json.dumps(playerStats["DeathsByWeapons"]))

    aSQLValues=(playerStats["CMID"],playerStats["MatchID"],pymysql.converters.escape_string(playerStats["Player"]),\
        playerStats["DWPlayerID"],playerStats["RCONPlayerID"],playerStats["SteamID"],\
        playerStats["Kills"],playerStats["Deaths"],playerStats["TKs"],\
        playerStats["KD"],playerStats["MaxKillStreak"],playerStats["KillsMin"],playerStats["DeathsMin"],\
        playerStats["MaxDeathStreak"],playerStats["MaxTKStreak"],playerStats["DeathByTK"],playerStats["DeathByTKStreak"],\
        playerStats["LongestLifeSec"],playerStats["ShortestLifeSec"],playerStats["MatchActiveTimeSec"],\
        strNemesis,strVictims,strKillsByWeapons,strDeathsByWeapons,\
        playerStats["CombatPoints"],playerStats["OffensePoints"],playerStats["DefensePoints"],playerStats["SupportPoints"])
    strsql=strsql % aSQLValues
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertPlayerStats 2",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(playerStats) + " ))")
        return -1

def sqlInsertNemesisList(dbcursor,nemesisList):

    strsql="INSERT INTO deathsbyplayer (MatchID,Victim,Killer,Deaths) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (nemesisList["MatchID"],pymysql.converters.escape_string(nemesisList["Victim"]),pymysql.converters.escape_string(nemesisList["Killer"]),nemesisList["Deaths"])
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertNemesisList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(nemesisList))
        return -1

def sqlInsertVictimList(dbcursor,victimList):

    strsql="INSERT INTO killsbyplayer (MatchID,Killer,Victim,Kills) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (victimList["MatchID"],pymysql.converters.escape_string(victimList["Killer"]),pymysql.converters.escape_string(victimList["Victim"]),victimList["Kills"])
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertVictimList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(victimList))
        return -1

def sqlInsertWeaponKillsList(dbcursor,weaponList):

    strsql="INSERT INTO weaponkillsbyplayer (MatchID,Player,Weapon,Kills) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (weaponList["MatchID"],pymysql.converters.escape_string(weaponList["Player"]),pymysql.converters.escape_string(weaponList["Weapon"]),weaponList["Kills"])
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertWeaponKillsList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(weaponList) + " ))")
        return -1

def sqlInsertWeaponDeathsList(dbcursor,weaponList):

    strsql="INSERT INTO weapondeathsbyplayer (MatchID,Player,Weapon,Deaths) VALUES (%s,'%s','%s',%s)"
    strsql=strsql % (weaponList["MatchID"],pymysql.converters.escape_string(weaponList["Player"]),pymysql.converters.escape_string(weaponList["Weapon"]),weaponList["Deaths"])
    try:
        dbcursor.execute(strsql)
        return 0
    except Exception as ex:
        HLL_DW_error.log_error("HLL_DW_DBLoad.py sqlInsertWeaponDeathsList 1",str(ex.args),str(type(ex)),"Error in SQL sentence >> (( " + strsql + " )) for array (( " + str(weaponList) + " ))")
        return -1


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
                playerStats["DeathsByWeapons"]=jsonPlayerStats["death_by_weapons"]
                playerStats["CombatPoints"]=str(jsonPlayerStats["combat"])
                playerStats["OffensePoints"]=str(jsonPlayerStats["offense"])
                playerStats["DefensePoints"]=str(jsonPlayerStats["defense"])
                playerStats["SupportPoints"]=str(jsonPlayerStats["support"])
            except:
                playerStats["DeathsByWeapons"]=""
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

def dwDbLoadMatchJSON(matchInfofromCSV,matchStatsInfofromURL,statsPageBody,dbserver,dbuser,dbpass,dbname,dbcharset):
    """Loads a new single match and its stats into DW database and commits if succeed

    Args:
        matchInfofromCSV (dict): Match info from CSV bulk load file HLL_DW_ETL_list.csv
        matchStatsInfofromURL (dict): Match info from stats URL
        statsPageBody (string): JSON from match stats page
        dbserver (string): IP or dns name for rdbms server
        dbuser (string): database login user
        dbpass (string): database login password
        dbname (string): database name / schema
        dbcharset (string): database charset, i.e. utf8mb4

    Returns:
        int: 0 if match is loaded successfully; <0 if error (number of errors found)
    """

    iOK=0
    try:
        #Open SQL connection to database and cursor for execute SQL sentences
        dbConn=sqlConnect(dbserver,dbuser,dbpass,dbname,dbcharset)
        dbcursor=sqlOpenCursor(dbConn)

        MatchDbID=dbInsertNewMatchRecord(matchInfofromCSV,matchStatsInfofromURL,statsPageBody,dbcursor)
        if MatchDbID>0:
            iOK+=dbLoadPlayerStats(matchInfofromCSV,MatchDbID,statsPageBody,dbcursor)
            iOK+=sqlFillPlayerClanAndTAG (dbcursor,MatchDbID)
            iOK+=sqlFillPlayerMatchSide (dbcursor,MatchDbID)
        else:
            iOK+=MatchDbID
            return iOK-1

        #Close sql cursor an database connection
        sqlCloseCursor(dbcursor)
        sqlCommit(dbConn)
        sqlCloseConnection(dbConn)
        return iOK
    
    except Exception as ex:          
        HLL_DW_error.log_error("HLL_DW_DBLoad.py dwDbLoadJSONFile 1",str(ex.args),str(type(ex)),"Error loading into database for Match ID = " + str(matchInfofromCSV) + "-" + str(matchStatsInfofromURL))    
        sqlCloseCursor(dbcursor)
        sqlCloseConnection(dbConn)
        return iOK-1

