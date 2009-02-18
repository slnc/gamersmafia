from Db import Db
from DbGM3 import DbGM3

def get_approved_by_for(type_name, cel_id):
    dbaction = Db.query_single('''select a.action_id from actions_r_parameters as a
                                    join actions_r_parameters as b on (a.action_id = b.action_id)
                                   where a.parameter_id = (select id 
                                                             from actions_types_parameters 
                                                            where type_id = (select id 
                                                                               from actions_types 
                                                                              where name = 'celement_publish') 
                                                              and name = 'celement_type_id')
                                     and b.parameter_id = (select id 
                                                             from actions_types_parameters 
                                                            where type_id = (select id 
                                                                               from actions_types 
                                                                              where name = 'celement_publish') 
                                                              and name = 'celement_id')
                                     and a.value        = '%s'
                                     and b.value        = %i''' % (type_name, cel_id))

    if not dbaction:
        return None
    else:
        user = Db.query_single('SELECT user_id from actions where id = %i' % dbaction['action_id'])
        return user['user_id']
