from Db import Db
from DbGM3 import DbGM3

from common import *

gm3_ctype = DbGM3.query_single('SELECT id from content_types where name = \'blogentry\'')['id']
money_for_users = {}

for dbentry in Db.query('SELECT * FROM o3_users.blogentries'):
    if dbentry['text'] == '' or not dbentry['text']:
        newcontent = '(Entrada en blanco)'
    else:
        newcontent = dbentry['text']
    
    DbGM3.insert('blogentries', {'id': dbentry['id'], 'created_on':dbentry['tstamp_created'], 'updated_on':dbentry['tstamp_created'], 'title':dbentry['title'].decode('utf8').encode('latin1'), 'user_id':dbentry['public_user_id'], 'content':newcontent.decode('utf8').encode('latin1')})

    if not money_for_users.has_key(dbentry['public_user_id']):
        money_for_users[dbentry['public_user_id']] = 0

    money_for_users[dbentry['public_user_id']] += 4

    DbGM3.query('update users set cache_karma_points = cache_karma_points + 20 WHERE id = %i' % int(dbentry['public_user_id']))

    newcontent_id = DbGM3.insert('contents', {'content_type_id':gm3_ctype, 'external_id':dbentry['id'], 'updated_on':dbentry['tstamp_created'], 'name':dbentry['title']}, True)

    # comments
    i = 0
    for dbcomment in Db.query('SELECT * FROM o3_websites.comments_o3_users_blogentries where o3_users_blogentry_id = %i' % dbentry['id']):
        DbGM3.insert('comments', {'content_id':newcontent_id, 'user_id':dbcomment['public_user_id'], 'host': dbcomment['ip'], 'created_on': dbcomment['tstamp_created'], 'updated_on': dbcomment['tstamp_lastupdated'], 'comment': dbcomment['text'].decode('utf8').encode('latin1')})
        i += 1

        DbGM3.query('update users set cache_karma_points = cache_karma_points + 5 WHERE id = %i' % int(dbcomment['public_user_id']))

        if not money_for_users.has_key(dbcomment['public_user_id']):
            money_for_users[dbcomment['public_user_id']] = 0

        money_for_users[dbcomment['public_user_id']] += 1

    DbGM3.query('update contents set comments_count = %i where id = %i' % (i, newcontent_id))
    # TODO actualizar cache_comments_count de tabla blogentries


for k in money_for_users:
    DbGM3.insert('cash_movements', {'description': 'Karma por comentarios y entradas a blogs', 'object_id_to':k, 'ammount':money_for_users[k], 'object_id_to_class':'User'})
    DbGM3.query('update users set cash = cash + %i WHERE id = %i' % (money_for_users[k], int(dbcomment['public_user_id'])))
    print 'user_id: %i | ammount: %i' % (k, money_for_users[k])

restart_id = DbGM3.query_single('''select max(id) from blogentries''')['max']
DbGM3.query('''alter sequence blogentries_id_seq RESTART %i''' % (restart_id+1))
