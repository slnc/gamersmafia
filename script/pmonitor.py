#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Este script se asegura de monitorizar la web para asegurarse de que si algo
# se rompe vuelva a estar en estado operativo.
import os
import glob
import re
import socket
import sys
import time
import urllib2


# START config
webapp = 'gamersmafia.com'
homeurl = 'gamersmafia.com'
max_mem = 200000 # size in KiB (1024)
base_dir = "/home/httpd/websites/%s/current" % webapp
pids_dir = "%s/tmp/pids/" % base_dir
DEBUG = False
# END config

class NoSaneMongrelFound(Exception):
    pass


def get_proc_out():
    return os.popen('ps aux | grep mongrel_rails').read()


def clear_invalid_pids():
    # lee archivos de pids y elimina los que hagan referencia a procesos que no se estan ejecutando
    global pids_dir
    pids_list = glob.glob("%sdispatch.*.pid" % pids_dir)
    proc_out = get_proc_out()
    for pid_file in pids_list:
        #print pid_file
        if os.path.exists("%s" % pid_file):
            if DEBUG:
            	print "cleaning pid file"
            pid = open("%s" % pid_file).read()
            m = re.search('httpd[\W]+%d[\W]+[0-9.]+[\W]+[0-9.]+[\W]+([0-9]+)' % int(pid), proc_out)
            if m == None:
                os.unlink("%s" % pid_file)


def spin():
    clear_invalid_pids()
    FNULL = open('/dev/null', 'w')
    os.popen('cd /home/httpd/websites/%s/current && ./script/spin' % webapp)
    time.sleep(7)


def get_lucky():
    # busca el primer mongrel que responda a requests
    global num_processes

    for i in range(num_processes):
        if mongrel_is_alive(8000+i):
            # ya tenemos al lucky one, buscamos su pid
            m = re.search('httpd[\W]+([0-9]+)[\W]+[0-9.]+[\W]+[0-9.]+[\W]+([0-9]+).*dispatch.%s.pid' % (8000+i), get_proc_out())
            if m == None:
                raise NoSaneMongrelFound('Can\'t find lucky one in proc table')
            else:
                return m.group(1) # TODO to test this

    raise NoSaneMongrelFound('Can\'t find lucky one in proc table')


def get_running_mongrels():
    # devuelve lista de tuplas (pid, port) de los mongrels en ejecucion
    d = os.popen('ps aux | grep mongrel_rails').read()
    mongrels = []
    for l in d.split('\n'):
        if l.find('grep') != -1:
            continue
        m = re.search('httpd[\W]+([0-9]+)[\W]+[0-9.]+[\W]+[0-9.]+[\W]+([0-9]+)', l)
        if m:
            mport = re.search('dispatch.([0-9]+).pid', l)
            if mport == None:
		if DEBUG:
	            print "l NO contiene dispatch.pid!"
                    print l
            else:
                mongrels.append((m.group(1), mport.group(1), m.group(2)))
            #print "mongrel info %s %s %s" % (m.group(1), mport.group(1), m.group(2))

    return mongrels

def mongrel_is_alive(port):
    req = urllib2.Request('http://127.0.0.1:%i/' % port)
    req.add_header('User-Agent', '%s Maintenance Script' % webapp)
    req.add_header('Host', webapp)
    try:
        r = urllib2.urlopen(req)
    except urllib2.URLError, e:
        return False
    else:
        return True


def check_mongrel(pid, port, mem):
    # mata el pid si no cumple las siguientes condiciones:
    # - que responda
    # - que tenga pid
    # - que no sobrepase el limite de memoria
    global pids_dir, max_mem

    if not mongrel_is_alive(int(port)):
        if DEBUG:
        	print "mongrel is dead"
        kill_mongrel(pid)
    elif not os.path.exists("%s/dispatch.%s.pid" % (pids_dir, port)):
    	if DEBUG:
        	print "no pid file"
        kill_mongrel(pid)
    elif file("%s/dispatch.%s.pid" % (pids_dir, port)).read() != pid:
        if DEBUG:
        	print "pid file has different pid"
        kill_mongrel(pid)
        os.unlink("%s/dispatch.%s.pid" % (pids_dir, port))
    elif int(mem) > max_mem:
        if DEBUG:
        	print "max mem"
        kill_mongrel(pid)
        os.unlink("%s/dispatch.%s.pid" % (pids_dir, port))


def kill_mongrel(pid):
    global dirty
    dirty = True
    if DEBUG:
    	print "killing mongrel %s" % pid
    os.popen('kill -9 %s' % pid)


def get_num_processes():
    global base_dir
    spin_body = open('%s/script/spin' % base_dir).read()
    m = re.search('-i ([0-9]+)$', spin_body)
    if m == None:
        raise Exception('InvalidSpinFile')
    return int(m.group(1))


def check_full_stack():
    try:
        req = urllib2.Request('http://%s/' % homeurl)
        r = urllib2.urlopen(req)
        body = r.read()
        if not re.search('google-analytics.com', body): # si no hay error pero no sale urchinTracker es que tb ha habido error
          print "No urchinTracker found, raising URLError"
          raise urllib2.URLError
    except urllib2.URLError, e:
        print "Error al comprobar el stack completo Apache + Mongrel: %s" % e
        mainloop()


def mainloop():
    global num_processes, dirty
    dirty = False
    socket.setdefaulttimeout(10)
    num_processes = get_num_processes()
    pid_lucky = None
    while pid_lucky == None:
        try:
            pid_lucky = get_lucky()
        except NoSaneMongrelFound:
            print "No sane mongrel found, retrying.."
            spin()
            time.sleep(5)
            pid_lucky = get_lucky()

    # print "lucky pid: %s" % pid_lucky
    for pid, port, mem in get_running_mongrels():
        if int(pid) == int(pid_lucky):
            port_lucky = port
            mem_lucky = mem
        else:
            check_mongrel(pid, port, mem)

    if len(get_running_mongrels()) < num_processes:
       if DEBUG:
       		print "%d mongrels are missing in action" % (num_processes - len(get_running_mongrels()))
       dirty = True

    if dirty == True: # seguro que algo anda mal
        spin()

    dirty = False
    check_mongrel(pid_lucky, port_lucky, mem_lucky)

    if dirty == True: # el lucky era un ilegal
        spin()

    check_full_stack()

if __name__ == '__main__':
    mainloop()
