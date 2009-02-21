import os
import psycopg2
import re
import socket
import string
import sys
import threading
import time


# CONFIGURATION
HOST='irc.quakenet.org' #The server we want to connect to
PORT=6667 #The connection port which is usually 6667
NICK='MrAlariko' #The bot's nickname
LOCALHOST='ice'
#IDENT='alariko'
REALNAME='GM Irc Spy'
OWNER='dharana' # The bot owner's nick
CHANNEL='#gamersmafia' # The default channel for the bot
readbuffer=''
BOT_USER_ID=23323 # alariko
POOLDIR = '/home/httpd/websites/gamersmafia.com/current/tmp/ircmsgs'
# END CONFIGURATION


def log(msg):
    "logs a message to the db"
    global dbconn, dbcurs

    if not dbconn:
        conn = psycopg2.connect('dbname=gamersmafia user=postgres')
        conn.set_isolation_level(0)

        curs = conn.cursor()
        curs.execute("INSERT INTO chatlines(line, user_id) VALUES(%(msg)s, %(user_id)s);", {'msg':msg.decode('latin1').encode('utf8', 'replace'), 'user_id':BOT_USER_ID}) # TODO escape

def dbclose():
    global dbconn

    if dbconn:
        dbconn.close()

def parsemsg(msg):
    # :dharana!n=dharana@87.217.160.17 PRIVMSG #gamersmafia :test
    complete=msg[1:].split(':', 1) #Parse the message into useful data
    info=complete[0].split(' ')
    msgpart=complete[1]
    sender=info[0].split('!')

    if msg.find('#gamersmafia') != -1 and sender[0] != '[RadioBehind]': # todo inseguro, usar ereg
        msgpart = msgpart.strip().replace('\003', '')
        log(('<%s>: %s' % (sender[0], msgpart)))

    #if msgpart[0]=='`' and sender[0]==OWNER: #Treat all messages starting with '`' as command
    #    cmd=msgpart[1:].split(' ')
    #    if cmd[0]=='op':
    #        s.send('MODE '+info[2]+' +o '+cmd[1]+'\n')
    #    if cmd[0]=='deop':
    #        s.send('MODE '+info[2]+' -o '+cmd[1]+'\n')
    #    if cmd[0]=='voice':
    #        s.send('MODE '+info[2]+' +v '+cmd[1]+'\n')
    #    if cmd[0]=='devoice':
    #        s.send('MODE '+info[2]+' -v '+cmd[1]+'\n')
    #    if cmd[0]=='sys':
    #        syscmd(msgpart[1:],info[2])
    #    
    #if msgpart[0]=='-' and sender[0]==OWNER : #Treat msgs with - as explicit command to send to server
    #    cmd=msgpart[1:]
    #    s.send(cmd+'\n')
    #    print 'cmd='+cmd


#def syscmd(commandline,channel):
#    cmd=commandline.replace('sys ','')
##    cmd=cmd.rstrip()
#    os.system(cmd+' >temp.txt')
#    a=open('temp.txt')
#    ot=a.read()
#    ot.replace('\n','|')
#    a.close()
#    s.send('PRIVMSG '+channel+' :'+ot+'\n')
#    return 0 

from Db import Db

class pool_messages:
    def __iter__(self):
        return self

    def next(self):
       # cogemos el siguiente archivo que haya por orden de fecha de modificación
       min_sv = None
       min_f = None
       
       dbc = Db.query('SELECT chatlines.id, chatlines.line, (select login from users where id = chatlines.user_id) as login FROM chatlines WHERE sent_to_irc = \'f\' AND created_on > now() - \'1 day\'::interval AND user_id <> %i ORDER BY created_on LIMIT 1' % BOT_USER_ID)
       
       if len(dbc) > 0:
           Db.query('UPDATE chatlines SET sent_to_irc = \'t\' WHERE id = %s' % dbc[0]['id'])
           return '<%s> %s' % (dbc[0]['login'], dbc[0]['line']) 
       else:
           raise StopIteration


class ListenerThread(threading.Thread):
    def run(self):
        # scanea el directorio de mensajes pendientes cada 10 secs
        global s, authed

        connected = False
        regexp = re.compile('[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0b\x0c\x0e\x0f\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f]')
        # regexp = re.compile('[\001\002\003\004\005\006\007\008\009\010\011\013\014\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031]')
        while 1:
            if connected:
                lines = s.recv(1024) # receive server messages
                if lines == '':
                    connected = False
                    authed = False

                print lines #server message is output

                for line in lines.split('\n'):
                    if(line.find('PING') != -1): #If server pings then pong  TODO esto pillará cualquier PING
                        l=line.rstrip().split()
                        s.send('PONG '+l[1]+'\n')

                    if authed == False and line.find('PING') != -1: # This is Crap(I wasn't sure about it but it works)
                        s.send('JOIN '+CHANNEL+'\n') #Join a channel
                        s.send('PRIVMSG Q@CServe.quakenet.org :AUTH MrAlariko YLlyXdy!2G\n')
                        s.send('MODE MrAlariko +x\n')
                        authed = True

                    line = regexp.sub('', line) # eliminamos caracteres de control
                    if line.find('PRIVMSG')!=-1 and line.find('PRIVMSG #gamersmafia :ACTION') == -1: #Call a parsing function
                        parsemsg(line)
            else:
                time.sleep(5)
                # print "conectando.."
                try:
                    connect()
                except Exception, inst:
                    print inst
                else:
                    connected = True
                # TODO añadir listado de usuarios online a la web, necesitamos parsear varios buffers hasta que digan que ha acabado if line.
                #:sw.de.quakenet.org 353 alariko = #gamersmafia :alariko @kr0n^ BkN|XeNo`bnc nano|mingo @crYpta|put0 @ESP|ReJeCt @dharana @cifra|Alexkid +APOCaLYPShit +SiCk``BNC +TheBlackDahlia eFk`Truko @L
                #:sw.de.quakenet.org 366 alariko #gamersmafia :End of /NAMES list.



class TalkerThread(threading.Thread):
    def run(self):
        global s, authed

        while 1:
            time.sleep(3) # antiflood
            if authed or None:
                # mandamos los mensajes que tengamos pendientes en POOLDIR
                for m in pool_messages():
                    for msg in m.split('\n'):
                        time.sleep(3) # antiflood
                        print 'PRIVMSG %s :%s\n' % (CHANNEL, msg.decode('utf8').encode('latin1', 'replace'))
                        s.send('PRIVMSG %s :%s\n' % (CHANNEL, msg.decode('utf8').encode('latin1', 'replace')))


class OnlineThread(threading.Thread):
    def run(self):
        global s, authed

        while 1:
            time.sleep(60)

            if authed:
                s.send('NAMES %s\n' % CHANNEL)


dbconn = dbcurs = None
authed = False
s = None

def connect():
    global dbconn, authed, s
    s = socket.socket() #Create the socket
    s.connect((HOST, PORT)) #Connect to server
    s.send('USER '+NICK+' '+LOCALHOST+' irc :'+REALNAME+'\n') #Identify to server 
    s.send('NICK '+NICK+'\n') #Send the nick to server

def run():
    #pidfile = 'tmp/pids/alariko.pid'
    #if os.path.exists?(pidfile)
    #f = open(pidfile, "w")
    #f.write("%d" % os.getpid())
    #f.close()

    try:
        ListenerThread().start()
        TalkerThread().start()
        # TODO no rula el detector OnlineThread().start()
    finally:
        dbclose()


if __name__ == '__main__':
    run()
