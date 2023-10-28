import configparser
import os.path
import logging
import HLL_DW_error

def getConfigArray(strlogfilename,strconfigfile):

    config = configparser.ConfigParser()

    try:
        logging.basicConfig(filename=strlogfilename, encoding='utf-8', level=logging.DEBUG, format='%(asctime)s %(levelname)s %(name)s %(message)s')
        if os.path.exists(strconfigfile) is False:
            raise Exception(strconfigfile + " file not found")

        config.read(strconfigfile,"utf-8")

    except Exception as ex:
        HLL_DW_error.log_error("GetConfig.py 1",str(ex.args),str(type(ex)),"Error loading HLL stats downloader configuration ini file >> " + strconfigfile)

    else:
        try:
            if len(config.sections()) > 0:
                configDict = {}
                configDict["jsonDestFilePath"] = config.get("Downloader","jsonDestFilePath")
                configDict["jsonRCONStatsUrl"] = config.get("Downloader","jsonRCONStatsUrl")
                configDict["matchesETLFile"] = config.get("Downloader","matchesETLFile")
                configDict["dbserver"] = config.get("HLLdatabase","dbserver")
                configDict["dbuser"] = config.get("HLLdatabase","dbuser")
                configDict["dbpass"] = config.get("HLLdatabase","dbpass")
                configDict["dbname"] = config.get("HLLdatabase","dbname")
                configDict["dbcharset"] = config.get("HLLdatabase","dbcharset")

                return configDict
        except Exception as ex2:
            HLL_DW_error.log_error("GetConfig.py 2",str(ex2.args),str(type(ex2)),"Error loading HLL stats downloader configuration ini file >> " + strconfigfile)
