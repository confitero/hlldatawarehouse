import requests
import io
import urllib3
import urllib.parse
import json
import HLL_DW_error
import HLL_DW_DBLoad

def parseURLGetMatchIDandServer (jsonRCONStatsUrlprefix,strline,strETLmatchesFileName,CSVLine):
    # Parse match stats URL line and get server matchID
    validSchemas = ("http","https","file")
    RCONmatchIDfromUrl = ""    
    dictUrl = {"RCONmatchIDfromUrl" : "", "server" : "", "schema" : "", "url" : ""}
    try:
        matchStatsURI=urllib.parse.urlparse(strline)
        strURLschema=matchStatsURI[0]
        strURLnetloc=matchStatsURI[1]
        strURLpath=matchStatsURI[2]+matchStatsURI[5]
        strURLfragment=matchStatsURI[5]
        RCONmatchIDfromUrl=strURLfragment[strURLfragment.rfind("/")+1:]
        if (strURLschema=="file"):
            RCONmatchIDfromUrl="0"
        if (strURLschema not in validSchemas) or (len(strURLnetloc)==0) or (len(strURLpath)==0) or not RCONmatchIDfromUrl.isnumeric():
            raise Exception("Invalid match stats URL in line while urlparsing line: " + str(CSVLine) + " >>> Line ||| " + strline + " |||")
        else:
            dictUrl["RCONmatchIDfromUrl"]=RCONmatchIDfromUrl
            dictUrl["server"]=strURLnetloc
            dictUrl["schema"]=strURLschema
            if (strURLschema!="file"):
                dictUrl["url"]=strURLschema + "://" + strURLnetloc + jsonRCONStatsUrlprefix + RCONmatchIDfromUrl
            else:
                dictUrl["url"]=strURLnetloc + strURLpath

    except Exception as ex:    
        HLL_DW_error.log_error("Extract_Stats.py parseURLGetMatchIDandServer 1",str(ex.args),str(type(ex)),"Error parsing matches stats URL from file >> " + strETLmatchesFileName + " >> Line " + str(CSVLine) + " ((" + strline + "))")
        return -1

    return dictUrl

def getAndSaveMatchJsonFile (strschema,statsurl,jsonDestFilePath):
# GetAndSaveMatchJson: Download the jSON match stats http page and save to a local file

    try:
        if strschema!="file":
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            statspage = requests.get(statsurl, verify=False) # HTTP/HTTPs get to download match stats in JSON format
            statsPageBodyTXT = statspage.text

            with io.open(jsonDestFilePath,'w',encoding='utf8') as jsonFile:
                jsonFile.write(statsPageBodyTXT)

            statspage.close()
            jsonFile.close()
        else:
            with io.open(statsurl.replace("%20"," "),'r',encoding='utf8') as jsonFile1:
                jsonStats = json.load(jsonFile1)
                statsPageBodyTXT = json.dumps(jsonStats)
            jsonFile1.close()
            
            with io.open(jsonDestFilePath,'w',encoding='utf8') as jsonFile2:
                json.dump(jsonStats,jsonFile2)
            jsonFile2.close()

        return statsPageBodyTXT
    except Exception as ex:
        HLL_DW_error.log_error("Extract_Stats.py getAndSaveMatchJsonFile 1",str(ex.args),str(type(ex)),"Error loading HLL matches stats file >> (( " + jsonDestFilePath + " )) from URL (( " + statsurl + "))")
        return ""
  

def getAndLoadMatch(matchInfofromCSV,hlldwconfig,CSVLine):
    """Download stats JSON from match stats URL and load it into DW database

    Args:
        matchInfofromCSV (dict): match info from CSV file
        hlldwconfig (dict): ini app config
        CSVLine (int): match CSV line number, used to report error in logging

    Returns:
        int: -1 if error; 0 if no match loaded; 1 if the match was loaded successfully
    """

    try:
        matchStatsInfofromURL = parseURLGetMatchIDandServer(hlldwconfig["jsonRCONStatsUrlprefix"],matchInfofromCSV["StatsUrl"],hlldwconfig["matchesETLFile"],CSVLine)
        matchStatsServer = matchStatsInfofromURL["server"] # Stat server IP or domain
        if matchStatsInfofromURL!=-1:
            if matchStatsInfofromURL["RCONmatchIDfromUrl"].isnumeric():
                matchJsonFileName = hlldwconfig["jsonDestFilePath"] + matchInfofromCSV["CMID"]  + "-" + matchStatsInfofromURL["RCONmatchIDfromUrl"] + "-" + matchStatsServer.replace(".","_").replace(":","_") + "-" + matchInfofromCSV["MatchName"].strip() + ".json"
                statsPageBody=getAndSaveMatchJsonFile (matchStatsInfofromURL["schema"],matchStatsInfofromURL["url"], matchJsonFileName) # GetAndSaveMatchJson: Download the jSON match stats http page and save to a local file
                if statsPageBody!="":
                    iResult=HLL_DW_DBLoad.dwDbLoadMatchJSON (matchInfofromCSV,matchStatsInfofromURL,statsPageBody,hlldwconfig["dbserver"],hlldwconfig["dbuser"],hlldwconfig["dbpass"],hlldwconfig["dbname"],hlldwconfig["dbcharset"])
                    if iResult==0:
                        return 1 # Returns 1 as 1 match succesfully loaded

        return iResult
    except Exception as ex:
        HLL_DW_error.log_error("Extract_Stats.py getAndLoadMatch 2",str(ex.args),str(type(ex)),"Error loading HLL single match >> (( " + matchJsonFileName + " )) from URL (( " + matchInfofromCSV["StatsUrl"] + "))")
        return -1