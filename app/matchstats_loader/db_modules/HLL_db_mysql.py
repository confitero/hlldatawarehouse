import mysql.connector
import pymysql

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset,pcollation,pport):
    dbconn = mysql.connector.connect(host=phost,user=puser,password=ppassword,database=pdatabase,port=pport)
    dbconn.set_charset_collation(pcharset,pcollation)
    return dbconn

def sqlStartTransaction (dbconn):
    None

def sqlCommit (dbconn):
    dbconn.commit()

def sqlCloseConnection (dbconn):
    dbconn.close()

def sqlOpenCursor(dbconn):
    return dbconn.cursor(buffered=True)

def sqlCloseCursor(dbcursor):
    dbcursor.close()

def sqlExecute(dbcursor,strsql,sqlparams):
    dbcursor.execute(strsql,sqlparams)
    return dbcursor.rowcount

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