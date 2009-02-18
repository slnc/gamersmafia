from Db import Db
from DbGM3 import DbGM3

from common import *

# relaciona juegos con categorías de primer nivel
relbasecat_id = {}

for dbgame in DbGM3.query('select code from games'):
    newid = DbGM3.insert('forum_forums', {'name': dbgame['code']}, True)
    relbasecat_id[dbgame['code']] = newid


map_old_cats_to_new = {}

def create_category(dbcategory, parent_id = None):
    #parent_id es el parent_id en gm3
    global map_old_cats_to_new
    newcatid = DbGM3.insert('forum_forums', {'name': dbcategory['name'], 'parent_id': parent_id, 'description': dbcategory['description']}, True)
    map_old_cats_to_new[dbcategory['id']] = newcatid

    # si hay hijas las creamos tb
    for dbsubcategory in Db.query('select * from celements_topics_category where parent_id = %i' % dbcategory['id']):
        create_category(dbsubcategory, newcatid)


# relaciona categorías de segundo nivel 
gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'forumtopic\'')['id']


for dbsubcommunity in Db.query('select a.id, b.code from subcommunities a join games b on a.game_id = b.id where type_id = 1;'):

    o1cats = Db.query('select * from celements_topics_category where subcommunity_id = %i and parent_id is null' % dbsubcommunity['id'])
    # replicamos la estructura de categorías de topics
    # primero recreamos la estructura de categorías
    for dbcategory in o1cats:
        create_category(dbcategory, relbasecat_id[dbsubcommunity['code']])


    # ahora iteramos a través de ella
    for dbcat in o1cats:

        for dbcel in Db.query('select * from celements_topics where category_id = %i' % dbcat['id']):
            newcel = {'id': dbcel['id'], 
                      'created_on': dbcel['creation_tstamp'],
                      'updated_on': dbcel['lastupdate_tstamp'],
                      'edited_on': dbcel['lastupdate_tstamp'],
                      'title': dbcel['title'],
                      'content': dbcel['text'],
                      'forum_forum_id': map_old_cats_to_new[dbcat['id']],
                      'user_id': dbcel['author_user_id'],
                      'hits_anonymous': dbcel['hits_anonymous'],
                      'hits_registered': dbcel['hits_registered']}

            if newcel['title'] == '' or not newcel['title']:
                newcel['title'] = '(Sin título)'

            if newcel['content'] == '' or not newcel['content']:
                newcel['content'] = '(En blanco)'

            DbGM3.insert('forum_topics', newcel)
            newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbcel['id'], 'updated_on':dbcel['lastupdate_tstamp'], 'name':newcel['title']}, True)

            # comments
            i = 0
            for dbcomment in Db.query('SELECT * FROM comments_celements_topics where item_id = %i' % dbcel['id']):
                DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['user_id'], 'host': dbcomment['host'], 'created_on': dbcomment['timestamp'], 'updated_on': dbcomment['timestamp'], 'comment': dbcomment['text']})
                i += 1

            DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))

restart_id = DbGM3.query_single('''select max(id) from forum_topics''')['max']
DbGM3.query('''alter sequence forum_topics_id_seq RESTART %i''' % (restart_id + 1))
