import requests
import io
import logging
import urllib3
import urllib.parse
import json
import HLL_DW_error

def parseURLGetMatchIDandServer (jsonRCONStatsUrlprefix,strline,strETLmatchesFileName,numLine):
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
            raise Exception("Invalid match stats URL in line while urlparsing line: " + str(numLine) + " >>> Line ||| " + strline + " |||")
        else:
            dictUrl["RCONmatchIDfromUrl"]=RCONmatchIDfromUrl
            dictUrl["server"]=strURLnetloc
            dictUrl["schema"]=strURLschema
            if (strURLschema!="file"):
                dictUrl["url"]=strURLschema + "://" + strURLnetloc + jsonRCONStatsUrlprefix + RCONmatchIDfromUrl
            else:
                dictUrl["url"]=strURLnetloc + strURLpath

    except Exception as ex:    
        HLL_DW_error.log_error("Extract_Stats.py parseURLGetMatchIDandServer 1",str(ex.args),str(type(ex)),"Error parsing matches stats URL from file >> " + strETLmatchesFileName + " >> Line " + str(numLine) + " ((" + strline + "))")
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