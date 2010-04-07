#!/usr/bin/env python
import os
import re
import time
import urllib2

def check_full_stack():
    try:
        req = urllib2.Request('http://www.gamersmafia.com/')
        r = urllib2.urlopen(req)
        body = r.read()
        if not re.search('google-analytics.com', body): # si no hay error pero no sale urchinTracker es que tb ha habido error
          print "No urchinTracker found, raising URLError"
          raise urllib2.URLError
    except urllib2.URLError, e:
        print "Error al comprobar el stack completo Apache + Mongrel: %s" % e


if __name__ == '__main__':
    try:
        check_full_stack()
    except Exception, e:
        os.system('/etc/init.d/apache stop')
        time.sleep(5)
        os.system('/etc/init.d/apache start')

