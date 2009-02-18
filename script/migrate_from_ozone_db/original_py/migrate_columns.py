import os.path
import shutil
from Db import Db
from DbGM3 import DbGM3

from common import *

# relaciona juegos con categorías de primer nivel
relbasecat_id = {}

for dbgame in DbGM3.query('select name, code from games'):
    newid = DbGM3.insert('columns_categories', {'name': dbgame['name'], 'code': dbgame['code']}, True)
    DbGM3.query('update columns_categories set toplevel_id = %s where name = \'%s\'' % (newid, dbgame['name'].replace('\'', '\\\'')))
    relbasecat_id[dbgame['code']] = newid


# relaciona categorías de segundo nivel 
secondlvlcats = {}

gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'column\'')['id']

# sabemos que las categorías de noticias son solo de primer nivel
for dbsubcommunity in Db.query('select a.id, b.code from subcommunities a join games b on a.game_id = b.id where type_id = 1;'):
    for dbcel in Db.query('select * from celements_columns where subcommunity_id = %i' % dbsubcommunity['id']):

        newcel = {'id': dbcel['id'], 
                  'created_on': dbcel['creation_tstamp'],
                  'updated_on': dbcel['lastupdate_tstamp'],
                  'edited_on': dbcel['lastupdate_tstamp'],
                  'title': dbcel['title'],
                  'summary': dbcel['description'],
                  'text': dbcel['content'],
                  'columns_category_id': relbasecat_id[dbsubcommunity['code']],
                  'user_id': dbcel['author_user_id'],
                  'approved_by_user_id': get_approved_by_for('columns', dbcel['id']),
                  'hits_anonymous': dbcel['hits_anonymous'],
                  'hits_registered': dbcel['hits_registered']}

        if newcel['summary'] == '' or not newcel['summary']:
            newcel['summary'] = '(Sin descripción)'

        if newcel['text'] == '' or not newcel['text']:
            newcel['text'] = '(Sin contenido)'
                   
        DbGM3.insert('columns', newcel)

        newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbcel['id'], 'updated_on':dbcel['lastupdate_tstamp'], 'name':newcel['id']}, True)

        # comments
        i = 0
        for dbcomment in Db.query('SELECT * FROM comments_celements_columns where item_id = %i' % dbcel['id']):
            DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['user_id'], 'host': dbcomment['host'], 'created_on': dbcomment['timestamp'], 'updated_on': dbcomment['timestamp'], 'comment': dbcomment['text']})
            i += 1

        DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))

restart_id = DbGM3.query_single('''select max(id) from columns''')['max']
DbGM3.query('''alter sequence columns_id_seq RESTART %i''' % (restart_id+1))
