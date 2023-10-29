import logging
import sys

def log_error(strline,exargs,errdesc,strmsg):

    log_line = "Error in " + strline + " || args: " + str(exargs) +  " || ErrDesc: " + errdesc + " ||ErrMsg: " + strmsg
    logging.error(log_line)
    if len(sys.argv)>1:
        if sys.argv[1] == "debug":
            print (log_line)