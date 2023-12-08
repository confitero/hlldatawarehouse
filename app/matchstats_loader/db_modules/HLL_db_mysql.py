import mysql.connector

def sqlConnect (phost,puser,ppassword,pdatabase,pcharset,pcollation):
    dbconn = mysql.connector.connect(host=phost,user=puser,password=ppassword,database=pdatabase,charset=pcharset,collation=pcollation)
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

def sqlExecute(dbcursor,strsql):
    dbcursor.execute(strsql)    
    return dbcursor.rowcount

def sqlAbort(dbconn):
    dbconn.rollback()