from encodings.utf_8 import encode
import logging
import HLL_DW_GetConfig
import HLL_DW_GetStats
import HLL_DW_error
import HLL_DW_DBLoad
import os,sys

# Logging file name
CstrLogfilename = "./HLL_DW.log"
# Config INI file name
CstrConfigfilename = "./HLL_DW_Config.ini"


# **************************************
# MAIN
# **************************************

#_______________________________________________________________________________________________________
# GetConfig >>> SECTION - BEGIN

#.....................................................................

HLL_DW_GetConfig.init()

for vArgument in sys.argv:
    print("Running arg: ",vArgument)
    if vArgument=="deletelog":
        if os.path.isfile(CstrLogfilename): os.remove(CstrLogfilename)
    if vArgument=="test":
        HLL_DW_GetConfig.runParams["cTest"]=1
    if vArgument=="debug":
        HLL_DW_GetConfig.runParams["cDebug"]=1
    if vArgument=="check":
        HLL_DW_GetConfig.runParams["cCheck"]=1
    if vArgument=="skip":
        HLL_DW_GetConfig.runParams["cSkip"]=1

# Initialize app logging in file CstrLogfilename
logging.basicConfig(filename=CstrLogfilename, encoding='utf-8', level=logging.ERROR, format='%(asctime)s %(levelname)s %(name)s %(message)s')

# Get app config from ini file CstrConfigfilename module HLL_DW_GetConfig.py
hlldwconfig = HLL_DW_GetConfig.getConfigArray (CstrLogfilename, CstrConfigfilename)
if hlldwconfig==-1:
    exit()

#_______________________________________________________________________________________________________
# LoadMatchesfromCSVBulkFile >>> SECTION - BEGIN


if HLL_DW_GetConfig.runParams["cTest"]==1: import tests_DW

# Get matches list to ETL and run ETL processes
#.....................................................................

# Process each stats match URL from .CSV load file matchesETLFile
iResult=0
dbConn=None
dbcursor=None

try:
    statslistfile = open(hlldwconfig["matchesETLFile"] , 'r')
    CSVLine = 0
    iProcessedMatchesOK = 0
    while True:
        CSVLine += 1
        strLine = statslistfile.readline()
        if not strLine:
            break
        if strLine.strip():
            if strLine[0:1] != "#":
                statsline = strLine.strip().split("|||")
                matchInfofromCSV = {}
                matchInfofromCSV["LoadType"] = statsline[0]
                if matchInfofromCSV["LoadType"]=="R":
                    # CSV batch line content for range to load into DW database: R|||CMID|||StatServerUrl|||MatchID-Start|||MatchID-End|||MatchNamePattern|||GameServerName|||GameServerIP|||GameServerOnwer|||MatchType|||CompetitionID
                    matchInfofromCSV["CMID"] = statsline[1]
                    matchInfofromCSV["StatServerUrl"] = statsline[2]
                    matchInfofromCSV["MatchID-Start"] = int(statsline[3])
                    matchInfofromCSV["MatchID-End"] = int(statsline[4])
                    matchInfofromCSV["MatchNamePattern"] = statsline[5]
                    matchInfofromCSV["GameServerName"] = statsline[6]
                    matchInfofromCSV["GameServerIP"] = statsline[7]
                    matchInfofromCSV["GameServerOwner"] = statsline[8]
                    matchInfofromCSV["MatchType"] = statsline[9]
                    matchInfofromCSV["CompetitionID"] = statsline[10]

                    matchInfofromCSV["ClansCoAllies"] = ""
                    matchInfofromCSV["ClansCoAxis"] = ""
                    matchInfofromCSV["ResultAllies"] = "0"
                    matchInfofromCSV["ResultAxis"] = "0"

                    dbConn,dbcursor,iResult=HLL_DW_DBLoad.dwDbOpenDB (hlldwconfig)
                    if iResult==0:

                        for iMatchID in range(matchInfofromCSV["MatchID-Start"],matchInfofromCSV["MatchID-End"]+1):
                            matchInfofromCSV["MatchName"] = matchInfofromCSV["MatchNamePattern"] + str(iMatchID)
                            matchInfofromCSV["MatchDesc"] = matchInfofromCSV["MatchNamePattern"] + " server match stats for RCON map_id " + str(iMatchID)
                            matchInfofromCSV["StatsUrl"] = matchInfofromCSV["StatServerUrl"] + hlldwconfig["statsURLprefix"] + str(iMatchID)
                            iOK=HLL_DW_GetStats.getAndLoadMatch(dbConn,dbcursor,matchInfofromCSV,hlldwconfig,CSVLine)
                            if iOK>=0:
                                iProcessedMatchesOK+=1                                
                                if HLL_DW_GetConfig.runParams["cDebug"]: print(iProcessedMatchesOK,end="\r",flush=True)
                            else:
                                if HLL_DW_GetConfig.runParams["cDebug"]: print("x",end="",flush=True)                        
                        HLL_DW_DBLoad.dwDbCloseDB(dbConn,dbcursor)
                    else:
                        iResult-=1

                if matchInfofromCSV["LoadType"]=="S":
                    # CSV batch line content for new match to load into DW database: S CMID StatsUrl MatchName MatchDesc ClansCoAllies ClansCoAxis GameServerName GameServerIP GameServerOwner ResultAllies ResultAxis MatchType CompetitionID
                    matchInfofromCSV["CMID"] = statsline[1]
                    matchInfofromCSV["StatsUrl"] = statsline[2]
                    matchInfofromCSV["MatchName"] = statsline[3]
                    matchInfofromCSV["MatchDesc"] = statsline[4]
                    matchInfofromCSV["ClansCoAllies"] = statsline[5]
                    matchInfofromCSV["ClansCoAxis"] = statsline[6]
                    matchInfofromCSV["GameServerName"] = statsline[7]
                    matchInfofromCSV["GameServerIP"] = statsline[8]
                    matchInfofromCSV["GameServerOwner"] = statsline[9]
                    matchInfofromCSV["ResultAllies"] = statsline[10]
                    matchInfofromCSV["ResultAxis"] = statsline[11]
                    matchInfofromCSV["MatchType"] = statsline[12]
                    matchInfofromCSV["CompetitionID"] = statsline[13]
                    if matchInfofromCSV["StatsUrl"]:
                        dbConn,dbcursor,iResult=HLL_DW_DBLoad.dwDbOpenDB (hlldwconfig)
                        if iResult==0:

                            if HLL_DW_GetStats.getAndLoadMatch(dbConn,dbcursor,matchInfofromCSV,hlldwconfig,CSVLine)>=0:
                                iProcessedMatchesOK+=1
                                if HLL_DW_GetConfig.runParams["cDebug"]: print(".",end="",flush=True)
                            else:
                                if HLL_DW_GetConfig.runParams["cDebug"]: print("x",end="",flush=True)                        

                            HLL_DW_DBLoad.dwDbCloseDB(dbConn,dbcursor)

                    else:
                        iResult-=1

                if matchInfofromCSV["LoadType"]=="M":
                    # CSV batch line content for range to load into DW database: M|||CMID|||StatServerUrl|||MatchNamePattern|||GameServerName|||GameServerIP|||GameServerOnwer|||MatchType|||CompetitionID|||MatchID's(comma separated)
                    matchInfofromCSV["CMID"] = statsline[1]
                    matchInfofromCSV["StatServerUrl"] = statsline[2]
                    matchInfofromCSV["MatchNamePattern"] = statsline[3]
                    matchInfofromCSV["GameServerName"] = statsline[4]
                    matchInfofromCSV["GameServerIP"] = statsline[5]
                    matchInfofromCSV["GameServerOwner"] = statsline[6]
                    matchInfofromCSV["MatchType"] = statsline[7]
                    matchInfofromCSV["CompetitionID"] = statsline[8]

                    matchInfofromCSV["ClansCoAllies"] = ""
                    matchInfofromCSV["ClansCoAxis"] = ""
                    matchInfofromCSV["ResultAllies"] = "0"
                    matchInfofromCSV["ResultAxis"] = "0"

                    listOfMatches = []
                    listOfMatches = statsline[9].strip().split(",")

                    dbConn,dbcursor,iResult=HLL_DW_DBLoad.dwDbOpenDB (hlldwconfig)
                    if iResult==0:
                        for iMatchID in listOfMatches:
                            matchInfofromCSV["MatchName"] = matchInfofromCSV["MatchNamePattern"] + str(iMatchID)
                            matchInfofromCSV["MatchDesc"] = matchInfofromCSV["MatchNamePattern"] + " server match stats for RCON map_id " + str(iMatchID)
                            matchInfofromCSV["StatsUrl"] = matchInfofromCSV["StatServerUrl"] + hlldwconfig["statsURLprefix"] + str(iMatchID)
                            iOK=HLL_DW_GetStats.getAndLoadMatch(dbConn,dbcursor,matchInfofromCSV,hlldwconfig,CSVLine)
                            if iOK>=0:
                                iProcessedMatchesOK+=1
                                if HLL_DW_GetConfig.runParams["cDebug"]: print(".",end="",flush=True)
                            else:
                                if HLL_DW_GetConfig.runParams["cDebug"]: print("x",end="",flush=True)                        
                        HLL_DW_DBLoad.dwDbCloseDB(dbConn,dbcursor)
                    else:
                        iResult-=1

    statslistfile.close()
    if iResult<0:
        print ("Errors = " + str(iResult) + ". See file " + CstrLogfilename)
    else:
        print ("")
        print ("Processed matches OK: " + str(iProcessedMatchesOK))

except Exception as ex:
    HLL_DW_error.log_error("Main.py LoadMatchesfromCSVBulkFile SECTION 2",str(ex.args),str(type(ex)),"Error loading HLL matches stats from CSV line " + str(CSVLine))



