from encodings.utf_8 import encode
import logging
import HLL_DW_GetConfig
import HLL_DW_GetStats
import HLL_DW_DBLoad
import HLL_DW_error

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

# Initialize app logging in file CstrLogfilename
logging.basicConfig(filename=CstrLogfilename, encoding='utf-8', level=logging.ERROR, format='%(asctime)s %(levelname)s %(name)s %(message)s')

# Get app config from ini file CstrConfigfilename module HLL_DW_GetConfig.py
hlldwconfig = HLL_DW_GetConfig.getConfigArray (CstrLogfilename, CstrConfigfilename)
try:
    jsonDestFilePath = hlldwconfig["jsonDestFilePath"] # Destination diretory for downloaded match stats json files
    jsonRCONStatsUrlprefix = hlldwconfig["jsonRCONStatsUrl"] # Url path to CRCON JSON stats (except matchID)
    matchesETLFile = hlldwconfig["matchesETLFile"] # File name including new matches to ETL to datawarehouse
    dbserver = hlldwconfig["dbserver"]
    dbuser = hlldwconfig["dbuser"]
    dbpass = hlldwconfig["dbpass"]
    dbname = hlldwconfig["dbname"]
    dbcharset = hlldwconfig["dbcharset"]
except Exception as ex:
    HLL_DW_error.log_error("Main.py GetConfig SECTION 1",str(ex.args),str(type(ex)),"Error loading HLL stats downloader configuration variables from file >> " + CstrConfigfilename)
    exit()

#_______________________________________________________________________________________________________
# GetMatchesToDownload >>> SECTION - BEGIN

# Get matches list to ETL and run ETL processes
# TO-DO here: write code to get matches ID and HLL CRCON stats URL from a new basic text file (multiline: MatchID URLstats) variable matchesETLfilePath
#.....................................................................

# Process each stats match URL from .CSV load file matchesETLFile
try:
    matchJsonFileName = ""
    jSonStatsURL = ""
    statsPageBody = ""

    statslistfile = open(matchesETLFile, 'r')
    count = 0
    iResult = 1
    iProcessedMatchesOK = 0
    while True:
        count += 1
        strLine = statslistfile.readline()
        if not strLine:
            break
        if strLine.strip():
            if strLine[0:1] != "#":
                statsline = strLine.strip().split("|||")
                matchInfofromCSV = {}
                if len(statsline)==13:
                    # CSV batch line content for new match to load into database: CMID StatsUrl MatchName MatchDesc ClansCoAllies ClansCoAxis GameServerName GameServerIP GameServerOwner ResultAllies ResultAxis MatchType CompetitionID
                    matchInfofromCSV["CMID"] = statsline[0]
                    matchInfofromCSV["StatsUrl"] = statsline[1]
                    matchInfofromCSV["MatchName"] = statsline[2]
                    matchInfofromCSV["MatchDesc"] = statsline[3]
                    matchInfofromCSV["ClansCoAllies"] = statsline[4]
                    matchInfofromCSV["ClansCoAxis"] = statsline[5]                    
                    matchInfofromCSV["GameServerName"] = statsline[6]
                    matchInfofromCSV["GameServerIP"] = statsline[7]
                    matchInfofromCSV["GameServerOwner"] = statsline[8]
                    matchInfofromCSV["ResultAllies"] = statsline[9]
                    matchInfofromCSV["ResultAxis"] = statsline[10]
                    matchInfofromCSV["MatchType"] = statsline[11]
                    matchInfofromCSV["CompetitionID"] = statsline[12]
                    
                if matchInfofromCSV["StatsUrl"]:
                    matchStatsInfofromURL = HLL_DW_GetStats.parseURLGetMatchIDandServer(jsonRCONStatsUrlprefix,matchInfofromCSV["StatsUrl"],matchesETLFile,count)
                    if matchStatsInfofromURL!=-1:
                        matchIDfromUrl = matchStatsInfofromURL["RCONmatchIDfromUrl"] # This is the RCON stat server match ID embed in stats URL page
                        matchStatsServer = matchStatsInfofromURL["server"] # Stat server IP or domain
                        if matchIDfromUrl.isnumeric():
                            jSonStatsURL = matchStatsInfofromURL["url"]
                            matchJsonFileName = jsonDestFilePath + matchInfofromCSV["CMID"]  + "-" + matchStatsInfofromURL["RCONmatchIDfromUrl"] + "-" + matchStatsServer.replace(".","_").replace(":","_") + "-" + matchInfofromCSV["MatchName"].strip() + ".json"
                            statsPageBody=HLL_DW_GetStats.getAndSaveMatchJsonFile (matchStatsInfofromURL["schema"],jSonStatsURL, matchJsonFileName) # GetAndSaveMatchJson: Download the jSON match stats http page and save to a local file
                            if statsPageBody!="":
                                iResult=HLL_DW_DBLoad.dwDbLoadMatchJSON (matchInfofromCSV,matchStatsInfofromURL,statsPageBody,dbserver,dbuser,dbpass,dbname,dbcharset)
                                if iResult==0:
                                    iProcessedMatchesOK += 1

    statslistfile.close()
    if iResult>0:
        print ("Errors = " + str(iResult) + ". See file " + CstrLogfilename)
    else:
        print ("Processed matches OK: " + str(iProcessedMatchesOK))

except Exception as ex:
    HLL_DW_error.log_error("Main.py GetMatchesToDownload SECTION 1",str(ex.args),str(type(ex)),"Error loading HLL matches stats line " + str(count) + " file >> (( " + matchJsonFileName + " )) from URL (( " + jSonStatsURL + "))")



