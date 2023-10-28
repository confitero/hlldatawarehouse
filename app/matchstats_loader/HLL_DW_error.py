import logging
import sys

def log_error(strline,exargs,errdesc,strmsg):

    logging.error(strline + exargs + errdesc + strmsg)
    if len(sys.argv)>1:
        if sys.argv[1] == "debug":
            print (strline + exargs + errdesc + strmsg)