import os
import threading, thread
import time

stop = False
mutex = thread.allocate_lock()

class PLinkThread(threading.Thread):
    def run(self):
        global stop
        p = os.popen('plink -N -batch -load tachikoma -R 13337:localhost:13337')
        while not stop:
            print 'PLinkThread awaiting'
            time.sleep(1)
        print 'PLinkThread finished'

class SvnServeThread(threading.Thread):
    def run(self):
        global stop
        p = os.popen('svnserve -d --listen-port 13337 --root c:\svn')
        while not stop:
            print 'SvnServeThread Awaiting..'
            time.sleep(1)
        print 'SvnServeThread finished'
            
class SvnSyncThread(threading.Thread):
    def run(self):
        global stop
        time.sleep(10)
        os.system('plink -load tachikoma -m c:\svn\gamersmafia\hooks\svnsync_gm.txt')
        stop = True
        print 'SvnSyncThread finished'
        
if __name__ == '__main__':
    SvnServeThread().start()
    PLinkThread().start()
    SvnSyncThread().start()
    while not stop:
        time.sleep(1)
        print 'main Awaiting..'
    print 'main finished'

# dumm
