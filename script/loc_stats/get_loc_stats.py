#!/usr/bin/env python
# Este script calcula las estadisticas de codigo del proyecto
# v1.0
import os
import os.path
import re
from tempfile import mkdtemp

# Config
repos = 'svn+ssh://hq.gamersmafia.com/home/slnc/svn/gamersmafia/trunk'
stats_dir = '/home/slnc/gm_stats'
graph_file = '/usr/local/hosting/confluence-2.4.5/confluence/images/graph_lines.png'
# End

last_rev_file = '%s/last' % stats_dir
data_file = '%s/stats.txt' % stats_dir

if __name__ == '__main__':
    if os.path.exists(stats_dir) == False:
        os.makedirs(stats_dir)

    if os.path.exists(last_rev_file) == False:
        start_rev = 1
    else:
        start_rev = (int)(file(last_rev_file).read())

    # Averiguamos ultima revision
    end_rev_full = os.popen('svn info %s' % repos).read()
    end_rev = (int)(re.search('Revision: ([0-9]+)\n', end_rev_full).group(1))


    basedir = mkdtemp()
    print basedir
    cmd = 'svn co -r1 %s %s' % (repos, basedir)
    p = os.popen(cmd)
    p.read()
    p.close()
    os.chdir(basedir)

    f = open(data_file, 'a+')

    try:
        for i in range(start_rev, end_rev):
            print i
            os.popen('svn up -q -r%s' % i)
            p = os.popen('rake stats')
            out = p.read()
            r_locs = re.search('Code LOC: ([0-9]+) ', out).group(1)
            t_locs = re.search('Test LOC: ([0-9]+) ', out).group(1)

            p2 = os.popen('svn info .')
            out2 = p2.read()
            p2.close()
            r_date = re.search('Last Changed Date: ([^$]+)$', out2).group(1)
            f.write("%s %s %s %s\n" % (i, r_locs, t_locs, r_date.strip()))

            open(last_rev_file, 'w').write('%i' % i)

            if i % 10 == 0:
                print 'rev: %s' % i
                f.flush()

    finally:
        f.close()
        os.popen('rm -rf %s' % basedir)
    
    # Actualizamos el archivo del wiki