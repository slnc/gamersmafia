#!/usr/bin/python
# -*- coding: utf-8 -*-
import xml.dom.minidom
import os
import re
import sys
import smtplib

# START CONFIG
wc_path = '/home/httpd/websites/gamersmafia.com/current/update.py'
wc_path_clean = '/home/httpd/websites/gamersmafia.com/current'
# END CONFIG


def getText(nodelist):
    rc = ""
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc = rc + node.data
    return rc

def compress_file(src, dst):
    p = os.popen('java -jar script/yuicompressor-2.3.6.jar %s -o %s --line-break 500' % (src, dst))

def compress_js():
    cfg = ['web.shared/jquery-1.2.6', 'web.shared/jquery.scrollTo-1.4.0', 'jquery-ui-personalized-1.6rc2', 'jrails', 'jquery.facebox', 'web.shared/jgcharts-0.9', 'web.shared/slnc', 'app', 'tracking', 'app.bbeditor']
    additional_libs = ['wseditor']

    dst = 'public/gm.js'
    f = file(dst, 'w')
    for o in cfg:
        f.write(file('public/javascripts/%s.js' % o).read())

    f.close()
    compress_file(dst, dst)
    
    for o in additional_libs:
    	compress_file('public/javascripts/%s.js' % o, 'public/javascripts/%s.pack.js' % o)
        # f.write(file('public/javascripts/%s.js' % o).read())
    

def send_changelog_email():
    p = os.popen('svn info %s/' % wc_path)
    cur_version = p.read()
    p.close()
    
    for w in ('Revision', 'Revisión'):
      pat = re.compile('%s: ([0-9]+)' % w)
      m = pat.search(cur_version)
      if m:
        cur_version = m.group(1)
        break

    # Treat the svnversion output. Possibles: 1025:1042, 1020M, etc
    semicolon = cur_version.find(':')
    if semicolon != -1:
        cur_version = cur_version[0:semicolon]
    cur_version = int(cur_version.replace('M', ''))

    try:
        prev_version = int(open('%s/public/storage/last_version' % wc_path_clean, 'r').read())
        prev_version += 1 # necesario para que no muestre última línea del commit anterior
    except IOError:
        prev_version = 2092

    p = os.popen('svn log --xml -r%d:%d `readlink %s`' % (prev_version, cur_version, wc_path_clean))
    log_output = p.read()
    p.close()

    try:
        dom = xml.dom.minidom.parseString(log_output)
    except xml.parsers.expat.ExpatError:
        print "WARNING: We are already on the last version!"
        sys.exit(0)
    else:
        log = "Listado de cambios\r\n\r\n"
    
        for entry in dom.getElementsByTagName('logentry'):
            if len(entry.getElementsByTagName('msg')) > 0:
                log = "%s\n\n%s" % (log, getText(entry.getElementsByTagName('msg')[0].childNodes).strip())
    
        # send the email
        fromaddr = 'webmaster@gamersmafia.com'
        toaddrs = 'dharana@gamersmafia.com'
    
        msg = ("Content-Type: text/plain; charset=UTF-8\r\nSubject: GM actualizada a la versión %d\r\nFrom: %s\r\nTo: %s\r\n\r\n%s" % (cur_version, fromaddr, toaddrs, log.encode('utf-8')))
        server = smtplib.SMTP('mail.gamersmafia.com')
        #server.set_debuglevel(1)
        server.login('nagato.gamersmafia.com', 'megustanlasgalletas')
        server.sendmail(fromaddr, toaddrs, msg)
        server.quit()
        
        open('%s/public/storage/last_version' % wc_path_clean, 'w').write('%i' % cur_version)

def app_update():
	output_dep = os.popen('rake gm:after_deploy').read()
	print output_dep

if __name__ == '__main__':
    os.popen('svnversion app > version')
    compress_js()
    send_changelog_email()
    app_update()
