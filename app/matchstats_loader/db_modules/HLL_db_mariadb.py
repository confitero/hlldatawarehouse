import pymysql

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset,pcollation):
    dbconn = pymysql.connect(host=phost,user=puser,password=ppassword,database=pdatabase,charset=pcharset,collation=pcollation)
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

def sqlExecute(dbcursor,strsql):
    ret=dbcursor.execute(strsql)    
    return ret    

def sqlAbort(dbconn):
    dbconn.rollback()

def sqlEscape(strSql):
    return pymysql.converters.escape_string(strSql)