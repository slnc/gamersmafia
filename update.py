#!/usr/bin/python
# -*- coding: utf-8 -*-
import xml.dom.minidom
import os
import re
import sys
import smtplib

# START CONFIG
wc_path = '/home/httpd/websites/gamersmafia/current/update.py'
wc_path_clean = '/home/httpd/websites/gamersmafia/current'
# END CONFIG


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
    cur = open('REVISION').read().strip()
    
    if os.path.exists('PREV_REVISION'):
        prev = open('PREV_REVISION').read().strip()
        interval = '%s..%s' % (prev, cur)
    else:
        prev = 'N/A'
        interval = ''
    
    log = os.system('echo -e `git log --pretty=format:"- %%s\\n%%b" %s production`' % interval).read()

    # send the email
    fromaddr = 'webmaster@gamersmafia.com'
    toaddrs = 'dharana@gamersmafia.com'

    msg = ("Content-Type: text/plain; charset=UTF-8\r\nSubject: GM actualizada a la versión %s\r\nFrom: %s\r\nTo: %s\r\n\r\n%s" % (cur, fromaddr, toaddrs, log))
    server = smtplib.SMTP('mail.gamersmafia.com')
    #server.set_debuglevel(1)
    server.login('nagato.gamersmafia.com', 'megustanlasgalletas')
    server.sendmail(fromaddr, toaddrs, msg)
    server.quit()
    
    open('%s/PREV_REVISION' % wc_path_clean, 'w').write('%s' % cur)
    os.popen('git add PREV_REVISION')
    os.popen('git commit -m "new deployment: %s"' % cur)
    os.popen('git push origin production')

def app_update():
	output_dep = os.popen('rake gm:after_deploy').read()
	print output_dep

if __name__ == '__main__':
    compress_js()
    send_changelog_email()
    app_update()
