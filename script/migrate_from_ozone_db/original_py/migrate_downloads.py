import os.path
import shutil
from Db import Db
from DbGM3 import DbGM3

from common import *

# relaciona juegos con categorías de primer nivel
relbasecat_id = {}

for dbgame in DbGM3.query('select * from games'):
    prev = DbGM3.query_single('SELECT * FROM downloads_categories where code = \'%s\' and parent_id is null' % dbgame['code'])

    if not prev:
        newid = DbGM3.insert('downloads_categories', {'name': dbgame['name'], 'code': dbgame['code']}, True)
        relbasecat_id[dbgame['code']] = newid
    else:
        relbasecat_id[dbgame['code']] = prev['id']


map_old_cats_to_new = {}

def create_category(dbcategory, parent_id = None):
    #parent_id es el parent_id en gm3
    global map_old_cats_to_new
    prev = DbGM3.query_single('SELECT * FROM downloads_categories where name = \'%s\' and parent_id = %s' % (dbcategory['name'].replace('\\', '\\\\'), parent_id))

    if not prev:
        newcatid = DbGM3.insert('downloads_categories', {'name': dbcategory['name'], 'parent_id': parent_id, 'description': dbcategory['description']}, True)
        map_old_cats_to_new[dbcategory['id']] = newcatid
    else:
        newcatid = int(prev['id'])
        map_old_cats_to_new[dbcategory['id']] = int(prev['id'])
        

    # si hay hijas las creamos tb
    for dbsubcategory in Db.query('select * from celements_files_category where parent_id = %i' % dbcategory['id']):
        create_category(dbsubcategory, newcatid)


# relaciona categorías de segundo nivel 
gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'download\'')['id']

# f_to_copy = file('/home/s1lence/files_pending_to_rsync.txt', 'w+')

i = 0
for dbsubcommunity in Db.query('select a.id, b.code from subcommunities a join games b on a.game_id = b.id where type_id = 1;'):

    o1cats = Db.query('select * from celements_files_category where subcommunity_id = %i and parent_id is null' % dbsubcommunity['id'])
    # replicamos la estructura de categorías de files
    # primero recreamos la estructura de categorías
    if dbsubcommunity['code'] in ('gw', 'ddr'):
        continue

    for dbcategory in o1cats:
        create_category(dbcategory, relbasecat_id[dbsubcommunity['code']])

    o1cats = Db.query('select * from celements_files_category where subcommunity_id = %i' % dbsubcommunity['id'])

    # ahora iteramos a través de ella
    for dbcat in o1cats:

        for dbcel in Db.query('select * from celements_files where category_id = %i' % dbcat['id']):
            impath = ('/storage/descargas/%i/%s' % (abs(int(dbcel['id']) / 1000), dbcel['file'])).replace('%', '%%')

            if not dbcel.has_key('id'):
                print "No tiene id!!!\n"

            try:
                newcel = {'id': dbcel['id'],
                          'created_on': dbcel['creation_tstamp'],
                          'updated_on': dbcel['lastupdate_tstamp'],
                          'edited_on': dbcel['lastupdate_tstamp'],
                          'name': dbcel['name'],
                          'description': dbcel['description'],
                          'downloads_category_id': map_old_cats_to_new[dbcat['id']],
                          'path': impath,
                          'user_id': dbcel['author_user_id'],
                          'approved_by_user_id': get_approved_by_for('files', dbcel['id']),
                          'hits_anonymous': dbcel['hits_anonymous'],
                          'hits_registered': dbcel['hits_registered']}
            except KeyError:
                print "    ERROR EN ARCHIVO: %s" % dbcel['id']
                continue


            if newcel['name'] == '' or not newcel['name']:
                newcel['name'] = '(Sin nombre)'

            if newcel['description'] == '' or not newcel['description']:
                newcel['description'] = '(En blanco)'

            if DbGM3.query_single('select id from downloads where id = %s' % dbcel['id']):
                print "Found matching file %s \"%s\", skipping.." % (dbcel['id'], newcel['name'])
            else:
                i += 1
                src = '/home/httpd/files_pending_ozone2/%s' % (dbcel['file'])

                print "Importing %s: %s" % (dbcel['id'], src)
                #f_to_copy.write("%s\n" % src)
                #continue

                while DbGM3.query_single('select id from downloads where path = \'%s\'' % impath):
                    # print 'found matching impath, iterating..'
                    impath = '%s/_%s' % (os.path.dirname(impath), os.path.basename(impath))
                    newcel['path'] = impath
                    
                DbGM3.insert('downloads', newcel)

                try:
                    f = file(src)
                except IOError:
                    print 'unable to open file %s' % src
                else:
                    f.close()
                    shutil.copy(src, '/home/httpd/websites/gamersmafia3/public' + impath)

                for dbmirror in Db.query('select * from celements_files_alternative_sources where celements_files_id = %i' % dbcel['id']):
                    DbGM3.insert('download_mirrors', {'download_id': dbcel['id'], 'url': dbmirror['name']})

                newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbcel['id'], 'updated_on':dbcel['lastupdate_tstamp'], 'name':newcel['name']}, True)

                # comments
                i = 0
                for dbcomment in Db.query('SELECT * FROM comments_celements_files where item_id = %i' % dbcel['id']):
                    DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['user_id'], 'host': dbcomment['host'], 'created_on': dbcomment['timestamp'], 'updated_on': dbcomment['timestamp'], 'comment': dbcomment['text']})
                    i += 1

                DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))

#f_to_copy.close()

print "\n%i archivos importados" % i

restart_id = DbGM3.query_single('''select max(id) from downloads''')['max']
DbGM3.query('''alter sequence downloads_id_seq RESTART %i''' % restart_id)
