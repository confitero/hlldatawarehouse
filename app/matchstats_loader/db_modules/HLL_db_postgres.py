import psycopg
import pymysql

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset,pcollation,pport):
    dbconn = psycopg.connect(host=phost,user=puser,password=ppassword,dbname=pdatabase,port=pport)
    return dbconn

def sqlStartTransaction (dbconn):
    ##Don't do anything because psycopg2 auto creates the transacction when DB connection is created
    # #dbconn.begin()
    return

def sqlCommit (dbconn):
    dbconn.commit()

def sqlCloseConnection (dbconn):
    dbconn.close()

def sqlOpenCursor(dbconn):
    return dbconn.cursor()

def sqlCloseCursor(dbcursor):
    dbcursor.close()

def sqlExecute(dbcursor,strsql,sqlparams):
    dbcursor.execute(strsql,sqlparams)
    return dbcursor.rowcount

def sqlAbort(dbconn):
    dbconn.rollback()

def sqlEscape(strSql):
    #No need to escape sql values in Postgresql using psycopg with execute second args as params
    return strSql

def sqlCollate(strSql):
    #Collate not applicable in Postgresql
    return strSql

def sqlMaxSmallInt():
    return 32767

def sqlMaxInt():
    return 2147483647

def sqllocateSubStr(psubstr, pstr):
    return f"position({psubstr} IN {pstr})>0"

def sqlUpdate(maintable,strfrom,strSETfields,strWHERE):
    return f"UPDATE {maintable} SET {strSETfields} FROM {strfrom} WHERE {strWHERE}"

def sqlPreCheckNumPlayers(dbcursor):
    return "SELECT CASE	WHEN (SELECT COUNT(*) FROM player)<>(SELECT count(*) FROM (SELECT count(*) FROM playerstats GROUP BY SteamID) a) THEN 1	ELSE 0 END;"

def sqlQuoteKeyword(strkeyword):
    return f"\"{strkeyword}\""