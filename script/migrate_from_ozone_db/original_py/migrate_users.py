from Db import Db
from DbGM3 import DbGM3

for dbuser in Db.query('SELECT * FROM users ORDER BY id asc'):
    if dbuser['account_activated']:
        confirmed = 1
    else:
        confirmed = 0
    
    newuser = {'id':dbuser['id'], 'login': dbuser['username'], 'cryptpassword': dbuser['password'], 'email': dbuser['email'], 'firstname': dbuser['name'], 'city': dbuser['city'], 'birthday': dbuser['birthday'], 'homepage': dbuser['homepage'], 'sex': dbuser['sex_selection'], 'msn': dbuser['msn'], 'icq': dbuser['icq'], 'send_global_announces': dbuser['send_global_announces'], 'domains':'', 'confirmed':confirmed }
    
    DbGM3.insert('users', newuser)
    
DbGM3.query('''alter sequence users_id_seq RESTART 18000;''')
DbGM3.query('''update users set domains = 'USERS,1 ';''')
DbGM3.query('''update users set domains='EDITORS,1 USERS,1 ADMIN,1' where id = 1;''')
DbGM3.query('''update users set ipaddr = '0.0.0.0';''')
