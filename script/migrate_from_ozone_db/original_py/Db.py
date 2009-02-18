import logging
from time import time

import psycopg2
import psycopg2.extras

class Db(object):
    '''Abstract class to interface with the database'''
    queries = 0
    timespent = 0
    db_conn = None

    @classmethod
    def query_single(self, query, repl=()):
        result = self.query(query, repl)

        if result and len(result) > 0:
            return result[0]
        else:
            return None


    @classmethod
    def update(self, table, dic_values, dic_cond):
        from ozone.storage.storable import AttrFile, AttrImage
        set_str = where_str = ''

        list_vals = []


        for i in dic_values:
            if dic_values[i] == '' or dic_values[i] == None:
                set_str = '%s, %s = NULL' % (set_str, i)
            elif dic_values[i].__class__ == AttrFile:
                set_str = '%s, %s = (%%s, %%s)' % (set_str, i)
                list_vals.append(dic_values[i].filename)
                list_vals.append(dic_values[i].original_name)
            elif dic_values[i].__class__ == AttrImage:
                set_str = '%s, %s = (%%s, %%s, %%s)' % (set_str, i)
                list_vals.append(dic_values[i].filename)
                list_vals.append(dic_values[i].original_name)
                list_vals.append(dic_values[i].format)
            else:
                set_str = '%s, %s = %%s' % (set_str, i)
                list_vals.append(dic_values[i])

        for i in dic_cond:
            where_str = '%s AND %s = %%s' % (where_str, i)
            list_vals.append(dic_cond[i])

        set_str = set_str[1:]
        where_str = where_str[4:]

        list_vals = [unicode(x).encode('utf-8') for x in list_vals]

        q = 'UPDATE %s SET %s WHERE %s' % (table, set_str, where_str)
        retval = self.query(q, list_vals)
        return retval


    @classmethod
    def delete(self, table, dic_cond):
        from ozone.storage.storable import AttrFile, AttrImage
        where_str = ''

        list_vals = []

        # TODO duplicated almost entirely
        for i in dic_cond:
            if dic_cond[i] == '' or dic_cond[i] == None:
                where_str = '%s AND %s = NULL' % (where_str, i)
            elif dic_cond[i].__class__ == AttrFile:
                where_str = '%s AND %s = (%%s, %%s)' % (where_str, i)
                list_vals.append(dic_cond[i].filename)
                list_vals.append(dic_cond[i].original_name)
            elif dic_cond[i].__class__ == AttrImage:
                where_str = '%s AND %s = (%%s, %%s, %%s)' % (where_str, i)
                list_vals.append(dic_cond[i].filename)
                list_vals.append(dic_cond[i].original_name)
                list_vals.append(dic_cond[i].format)
            else:
                where_str = '%s AND %s = %%s' % (where_str, i)
                list_vals.append(dic_cond[i])

        where_str = where_str[4:]

        list_vals = [unicode(x).encode('utf-8') for x in list_vals]

        q = 'DELETE FROM %s WHERE %s' % (table, where_str)
        return self.query(q, list_vals)


    @classmethod
    def insert(self, table, dict_vals, returnid=False):
        from ozone.storage.storable import AttrFile, AttrImage
        # note, dict keys must be correct, they won't be checked
        if returnid == True:
            next_id = self.query_single('''SELECT nextval(pg_get_serial_sequence(%s,'id'))''', (table,))

            if not next_id or type(next_id['nextval']) not in (int, long):
                raise Exception('next_id "%s" not an int but a %s' % (next_id['nextval'], type(next_id['nextval'])))

            obj_id = next_id
        elif dict_vals.has_key('id'):
            obj_id = dict_vals['id']
            

        columns_str = values_str = ''

        list_vals = []

        for i in dict_vals:
            columns_str = '%s, %s' % (columns_str, i)
            if dict_vals[i].__class__ == AttrFile:
                # NOTA como AttrFile tiene dos atributos (filename,
                # original_name) usamos ( ) para especificar el valor de input
                values_str = '%s, (%%s, %%s)' % (values_str)
            elif dict_vals[i].__class__ == AttrImage:
                # NOTA como AttrFile tiene dos atributos (filename,
                # original_name) usamos ( ) para especificar el valor de input
                values_str = '%s, (%%s, %%s, %%s)' % (values_str)
            else:
                values_str = '%s, %%s' % (values_str)

            if dict_vals[i].__class__ == AttrFile:
                # reemplazamos el id en el valor de filename ya que al ser
                # creado un storable no puede saber su id
                # en [0] viene el filename
                # en [1] viene el original_name del archivo subido
                # TODO str no, unicode! pero hay que testear bien
                list_vals.append('%s' % (str(dict_vals[i].filename) % obj_id))
                list_vals.append('%s' % (str(dict_vals[i].original_name)))
            elif dict_vals[i].__class__ == AttrImage:
                # reemplazamos el id en el valor de filename ya que al ser
                # creado un storable no puede saber su id
                # en [0] viene el filename
                # en [1] viene el original_name del archivo subido
                list_vals.append('%s' % (str(dict_vals[i].filename) % obj_id))
                list_vals.append('%s' % (str(dict_vals[i].original_name)))
                list_vals.append('fooformat')
            elif dict_vals[i].__class__ in (str, unicode):
                list_vals.append(dict_vals[i].encode('utf-8'))
            else:
                list_vals.append(dict_vals[i])

        columns_str = columns_str[1:]
        values_str = values_str[1:]

        if returnid == True:
            columns_str = 'id, %s' % columns_str
            values_str = '%%s, %s' % (values_str)
            list_vals = [next_id['nextval']] + list_vals

        # allow to insert records with only the id
        if columns_str.endswith(', ') and values_str.endswith(', '):
            columns_str = columns_str[:-2]
            values_str = columns_str[:-2]

        q = 'INSERT INTO %s (%s) VALUES(%s)' % (table, columns_str, values_str)
        retval = self.query(q, list_vals)

        if returnid == True:
            return next_id['nextval']
        else:
            return retval


    @classmethod
    def start_copy(self):
        self.triggerConnection()
        self.db_conn.set_isolation_level(1) # no autocommit
        self.query('BEGIN;')

    @classmethod
    def end_copy(self):
        self.triggerConnection()
        self.query('END;')
        self.db_conn.set_isolation_level(0) # autocommit

    @classmethod
    def query(self, query, repl=(), dontrestart=False):
        self.queries = self.queries + 1
        t_start = time()
        self.triggerConnection()
        q = self.db_conn.cursor(cursor_factory = psycopg2.extras.DictCursor)
        try:
            result = q.execute(query, repl)
        except (psycopg2.ProgrammingError, psycopg2.IntegrityError), inst:
            if str(inst).startswith('terminating connection due to administrator command') and dontrestart == False:
                # intentamos reiniciar la conexión
                logging.getLogger('app').warning('Psycopg OperationalError(%s). Restarting connection..' % inst)
                self.db_conn = None
                self.triggerConnection()
            elif (str(inst) == 'can\'t adapt'):
                raise Exception('%s: "%s" repls: %s / %s' % (str(inst)[:-1], query, repl, [type(x) for x in repl]))
            else:
                raise Exception('%s: "%s" repls: %s' % (str(inst)[:-1], query, repl))
        except TypeError, inst:
            raise TypeError('%s: "%s" repls: %s' % (str(inst)[:-1], query, repl))
        except IndexError, inst:
            raise IndexError('%s: "%s" repls: %s' % (str(inst)[:-1], query, repl))

        if query.lower().find('select', 0, 7) != -1:
            results = q.fetchall()
            self.timespent += (time() - t_start)
            return results
        else:
            self.timespent += (time() - t_start)
            return result
      
    @classmethod
    def triggerConnection(self):
        if not self.db_conn:
            try:
                self.db_conn = psycopg2.connect('dbname=gm_ozone2 user=postgres password=')
            except psycopg2.OperationalError, inst:
                logging.getLogger('app').critical('Unable to connect to db: %s' % inst)
                raise

            self.db_conn.set_isolation_level(0) # autocommit by default


    @classmethod
    def disconnect(self):
        try:
            self.db_conn.close()
            self.db_conn = None
        except AttributeError:
            pass
