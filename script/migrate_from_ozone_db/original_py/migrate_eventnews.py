from Db import Db
from DbGM3 import DbGM3

from common import *

gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'eventsnews\'')['id']

# sabemos que las categorías de noticias son solo de primer nivel
for dbsubcommunity in Db.query('select a.id, b.code from subcommunities a join games b on a.game_id = b.id where type_id = 1;'):

    for dbcel in Db.query('select * from celements_newscoverage where subcommunity_id = %i' % dbsubcommunity['id']):
        newcel = {'id': dbcel['id'], 
                  'created_on': dbcel['creation_tstamp'],
                  'updated_on': dbcel['lastupdate_tstamp'],
                  'edited_on': dbcel['lastupdate_tstamp'],
                  'title': dbcel['headline'],
                  'summary': dbcel['text'],
                  'additional_info': dbcel['text_extra'],
                  'event_id': dbcel['event_id'],
                  'user_id': dbcel['author_user_id'],
                  'approved_by_user_id': get_approved_by_for('newsCoverage', dbcel['id']),
                  'hits_anonymous': dbcel['hits_anonymous'],
                  'hits_registered': dbcel['hits_registered']}

        if not newcel['user_id'] or newcel['user_id'] == '':
            newcel['user_id'] = 1

        if not newcel['approved_by_user_id'] or newcel['approved_by_user_id'] == '':
            newcel['approved_by_user_id'] = 1

        if newcel['summary'] == '' or not newcel['summary']:
            newcel['summary'] = '(Sin texto)'

        if newcel['title'] == '' or not newcel['title']:
            newcel['title'] = '(Sin título)'

        DbGM3.insert('events_news', newcel)
        newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbcel['id'], 'updated_on':dbcel['lastupdate_tstamp'], 'name':newcel['title']}, True)

        # comments
        i = 0
        for dbcomment in Db.query('SELECT * FROM comments_celements_newscoverage where item_id = %i' % dbcel['id']):
            DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['user_id'], 'host': dbcomment['host'], 'created_on': dbcomment['timestamp'], 'updated_on': dbcomment['timestamp'], 'comment': dbcomment['text']})
            i += 1

        DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))

restart_id = DbGM3.query_single('''select max(id) from events_news''')['max']
DbGM3.query('''alter sequence events_news_id_seq RESTART %i''' % restart_id)
