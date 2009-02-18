import os.path
import shutil
from Db import Db
from DbGM3 import DbGM3

from common import *

# relaciona juegos con categorías de primer nivel
relbasecat_id = {}

for dbgame in DbGM3.query('select code from games'):
    newid = DbGM3.insert('images_categories', {'name': dbgame['code']}, True)
    relbasecat_id[dbgame['code']] = newid


# relaciona categorías de segundo nivel 
secondlvlcats = {}

gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'image\'')['id']

# sabemos que las categorías de noticias son solo de primer nivel
for dbsubcommunity in Db.query('select a.id, b.code from subcommunities a join games b on a.game_id = b.id where type_id = 1;'):

    for dbcat in Db.query('select * from celements_images_category where subcommunity_id = %i' % dbsubcommunity['id']):
        secondlvlcat_id = DbGM3.insert('images_categories', {'name': dbcat['name'], 'parent_id': relbasecat_id[dbsubcommunity['code']]}, True)
        secondlvlcats[dbcat['id']] = secondlvlcat_id

        for dbcel in Db.query('select * from celements_images where category_id = %i' % dbcat['id']):
            impath = ('/storage/imagenes/%i/%s' % (abs(int(dbcel['id']) / 1000), dbcel['file'])).replace('%', '%%')

            newcel = {'id': dbcel['id'], 
                      'created_on': dbcel['creation_tstamp'],
                      'updated_on': dbcel['lastupdate_tstamp'],
                      'edited_on': dbcel['lastupdate_tstamp'],
                      'description': dbcel['description'],
                      'path': impath,
                      'images_category_id': secondlvlcat_id,
                      'user_id': dbcel['author_user_id'],
                      'approved_by_user_id': get_approved_by_for('images', dbcel['id']),
                      'hits_anonymous': dbcel['hits_anonymous'],
                      'hits_registered': dbcel['hits_registered']}
                       
            while DbGM3.query_single('select id from images where path = \'%s\'' % impath):
                print 'found matching impath, iterating..'
                impath = '%s/_%s' % (os.path.dirname(impath), os.path.basename(impath))
                newcel['path'] = impath
                
            DbGM3.insert('images', newcel)
            src = '/mnt/backuplucy/gamersmafia/storage/celements/images/%i/file/%s' % (dbcel['id'], dbcel['file'])

            try:
                f = file(src)
            except IOError:
                print 'unable to open file %s' % src 
            else:
                f.close()
                shutil.copy(src, '/home/s1lence/websites/gamersmafia/public' + impath)

            newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbcel['id'], 'updated_on':dbcel['lastupdate_tstamp'], 'name':newcel['id']}, True)

            # comments
            i = 0
            for dbcomment in Db.query('SELECT * FROM comments_celements_images where item_id = %i' % dbcel['id']):
                DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['user_id'], 'host': dbcomment['host'], 'created_on': dbcomment['timestamp'], 'updated_on': dbcomment['timestamp'], 'comment': dbcomment['text']})
                i += 1

            DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))

restart_id = DbGM3.query_single('''select max(id) from images''')['max']
DbGM3.query('''alter sequence images_id_seq RESTART %i''' % restart_id)
