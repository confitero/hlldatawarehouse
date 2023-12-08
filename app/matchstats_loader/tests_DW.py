import pymysql
import json
import HLL_DW_GetConfig

# Server1: https://server.comunidadhll.es/api/get_map_scoreboard?map_id=1526376
# Server1: https://server.comunidadhll.es/#/gamescoreboard/1526376

# Server2: https://server.comunidadhll.es:5443/api/get_map_scoreboard?map_id=1526327
# Server2: https://server.comunidadhll.es:5443/#/gamescoreboard/1526327

# Server3: https://scoreboard.comunidadhll.es:3443/#/gamescoreboard/1526453
# Server3: https://scoreboard.comunidadhll.es:3443/api/get_map_scoreboard?map_id=1526453

print ("Test: " + str(HLL_DW_GetConfig.runParams["cTest"]))

##########################################
# Prueba de conexiones y collation con pymysql

dbconn = pymysql.connect(host=hlldwconfig["dbserver"],user=hlldwconfig["dbuser"],password=hlldwconfig["dbpass"],database=hlldwconfig["dbname"],charset=hlldwconfig["dbcharset"],collation=hlldwconfig["dbcollation"])

dbcursor=dbconn.cursor()

strSql="INSERT INTO prueba (campo) values ('A');"
dbcursor.execute(strSql)

strSql="INSERT INTO prueba (campo) values ('Á');"
dbcursor.execute(strSql)

strSql="INSERT INTO prueba (campo) values ('" + pymysql.converters.escape_string("Sh\u00e4d\u00f6w") + "');"
dbcursor.execute(strSql)

strSql="INSERT INTO prueba (campo) values ('Shadow');"
dbcursor.execute(strSql)

dbcursor.close()
dbconn.close()

exit()

print (pymysql.converters.escape_string("Sh\u00e4d\u00f6w"))


strsql="INSERT INTO PlayerStats (CMID,MatchID,Player,\
        DWPlayerID,RCONPlayerID,SteamID,\
        Kills,Deaths,TKs,\
        KD,MaxKillStreak,KillsMin,DeathsMin,\
        MaxDeathStreak,MaxTKStreak,DeathByTK,DeathByTKStreak,\
        LongestLifeSec,ShortestLifeSec,MatchActiveTimeSec,\
        Nemesis,Victims,KillsByWeapons,DeathsByWeapons,\
        CombatPoints,OffensePoints,DefensePoints,SupportPoints)\
        VALUES (%s)"
    

aSQLValues=(pymysql.converters.escape_string("Sh\u00e4d\u00f6w"))
strsql=strsql % aSQLValues
print (strsql)

exit()

import ast

s = "{'userna\'me':'dfdsfdsf'}"

print (ast.literal_eval(s))

exit()

#data = {'json"Key"': 'jsonValue',"title": "hello'world"}

data = {'[XXX] AA ♤': 1, '[XXX] AAñ': 2}

# get string with all double quotes
json_string = json.dumps(data) 
print (json_string)

exit()

strJSON="{\"id\": 395, \"player_id\": 292, \"player\": \"[129]ACHO\", \"steaminfo\": None, \"map_id\": 146, \"kills\": 33, \"kills_streak\": 4, \"deaths\": 35, \"deaths_without_kill_streak\": 9, \"teamkills\": 0, \"teamkills_streak\": 0, \"deaths_by_tk\": 1, \"deaths_by_tk_streak\": 1, \"nb_vote_started\": 0, \"nb_voted_yes\": 0, \"nb_voted_no\": 0, \"time_seconds\": 5213, \"kills_per_minute\": 0.38, \"deaths_per_minute\": 0.4, \"kill_death_ratio\": 0.94, \"longest_life_secs\": 640, \"shortest_life_secs\": 36, \"most_killed\": {\"【IR】CN\": 2, \"【IRS】pangf\": 1, \"【IR】Snever\": 4, \"【IR】小熊\": 2, \"【IRS】乂稹\": 1, \"【IRX】米奇\": 2, \"【IR S】MISSVII\": 1, \"【IRS】叁叁叁\": 1, \"【ＩＲ】屠夫\": 1, \"【IR】prince14891\": 3, \"【IR】捷森猪猪\": 3, \"【IR】摇摆摇摆\": 2, \"【IR S】追风墨痕\": 2, \"【IR】Karl Rundstedt\": 1, \"【IR】皮套人胡图图\": 1, \"【IRS】你能让我滋一下吗\": 2, \"【IR】大夫冲鸭!Σ( ° △ °||)\": 2, \"【IR】大夫奈斯!(｡･∀･)ﾉﾞ\": 2}, \"death_by\": {\"【IR】X\": 3, \"【IR】 Seer\": 1, \"【IR】Snever\": 2, \"【IR】凌物\": 2, \"【IR】风均\": 1, \"【IRS】乂稹\": 1, \"【IR】LiuLian\": 1, \"【IR S】MISSVII\": 1, \"【IR】Thylacine\": 2, \"【IRS】叁叁叁\": 3, \"【IR】prince14891\": 3, \"【IR】Salt of NaCl\": 2, \"【IR】捷森猪猪\": 2, \"【IR】摇摆摇摆\": 1, \"【IR】苦练急停\": 2, \"【IR S】追风墨痕\": 1, \"【IR】Karl Rundstedt\": 1, \"【IR】皮套人胡图图\": 3, \"【IR】 抢镜的最佳路人\": 1, \"【IR】大夫冲鸭!Σ( ° △ °||)\": 1, \"【IR】大夫奈斯!(｡･∀･)ﾉﾞ\": 1}, \"weapons\": {\"FG42 x4\": 18, \"KARABINER 98K x8\": 13, \"COAXIAL MG34 [Sd.Kfz.234 Puma]\": 2}}"

jsonNemesisList = json.loads(strJSON)        
nemesisList = {"MatchID": "", "Victim": "", "Killer": "", "Deaths": ""}

icount=1
for jsonNemesisItem in jsonNemesisList:
    """
    nemesisList["MatchID"]=str("1")
    nemesisList["Victim"]="player"
    nemesisList["Killer"]=str(jsonNemesisItem[0])
    nemesisList["Deaths"]=str(jsonNemesisItem[1])
    """
    print (str(icount) + " " + jsonNemesisItem + " " + str(jsonNemesisList[jsonNemesisItem]))
    icount+=1


