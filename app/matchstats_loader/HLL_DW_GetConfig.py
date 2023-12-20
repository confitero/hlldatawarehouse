import configparser
import os.path
import logging
import HLL_DW_error

def init():
    global runParams
    runParams = {}
    runParams["cTest"]=0
    runParams["cDebug"]=0
    runParams["cCheck"]=0
    runParams["cSkip"]=0

def getConfigArray(strlogfilename,strconfigfile):

    config = configparser.ConfigParser()

    try:
        logging.basicConfig(filename=strlogfilename, encoding='utf-8', level=logging.DEBUG, format='%(asctime)s %(levelname)s %(name)s %(message)s')
        if os.path.exists(strconfigfile) is False:
            raise Exception(strconfigfile + " file not found")

        config.read(strconfigfile,"utf-8")

        if len(config.sections()) > 0:
            configDict = {}
            configDict["jsonDestFilePath"] = config.get("Downloader","jsonDestFilePath")
            configDict["jsonRCONStatsUrlprefix"] = config.get("Downloader","jsonRCONStatsUrlprefix")
            configDict["statsURLprefix"] = "/#" + config.get("Downloader","statsURLprefix")
            configDict["matchesETLFile"] = config.get("Downloader","matchesETLFile")
            configDict["dbserver"] = config.get("HLLdatabase","dbserver")
            configDict["dbuser"] = config.get("HLLdatabase","dbuser")
            configDict["dbpass"] = config.get("HLLdatabase","dbpass")
            configDict["dbname"] = config.get("HLLdatabase","dbname")
            configDict["dbcharset"] = config.get("HLLdatabase","dbcharset")
            configDict["dbcollation"] = config.get("HLLdatabase","dbcollation")
            configDict["dbport"] = config.get("HLLdatabase","dbport")
            return configDict        
        else:
            raise Exception("Not valid ini sections or values not not found")

    except Exception as ex:
        HLL_DW_error.log_error("GetConfig.py 1",str(ex.args),str(type(ex)),"Error loading HLL stats downloader configuration ini file >> " + strconfigfile)
        return -1
