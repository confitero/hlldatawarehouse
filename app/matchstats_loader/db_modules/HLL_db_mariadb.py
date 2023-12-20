import pymysql

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset,pcollation,pport):
    dbconn = pymysql.connect(host=phost,user=puser,password=ppassword,database=pdatabase,charset=pcharset,collation=pcollation,port=pport)
    return dbconn

def sqlStartTransaction (dbconn):
    dbconn.begin()

def sqlCommit (dbconn):
    dbconn.commit()

def sqlCloseConnection (dbconn):
    dbconn.close()

def sqlOpenCursor(dbconn):
    return dbconn.cursor()

def sqlCloseCursor(dbcursor):
    dbcursor.close()

def sqlExecute(dbcursor,strsql,sqlparams):
    ret=dbcursor.execute(strsql,sqlparams)
    return ret

def sqlAbort(dbconn):
    dbconn.rollback()

def sqlEscape(strSql):
    return pymysql.converters.escape_string(strSql)

def sqlCollate(strSql):
    return strSql + " collate utf8mb4_unicode_ci"

def sqlMaxSmallInt():
    return 32767

def sqlMaxInt():
    return 2147483647

def sqllocateSubStr(psubstr, pstr):
    return f"locate({psubstr},{pstr})>0"

def sqlUpdate(maintable,strfrom,strSETfields,strWHERE):
    return f"UPDATE {maintable}, {strfrom} SET {strSETfields} WHERE {strWHERE}"
    
def sqlPreCheckNumPlayers(dbcursor):
    return "SELECT if((SELECT COUNT(Distinct SteamID) FROM player)<>(SELECT COUNT(DISTINCT SteamID) FROM playerstats),1,0) AS CheckNumPlayers;"

def sqlQuoteKeyword(strkeyword):
    return f"`{strkeyword}`"