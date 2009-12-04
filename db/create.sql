--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: _gamersmafia; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA _gamersmafia;


--
-- Name: archive; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA archive;


--
-- Name: stats; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stats;


--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = _gamersmafia, pg_catalog;

--
-- Name: vactables; Type: TYPE; Schema: _gamersmafia; Owner: -
--

CREATE TYPE vactables AS (
	nspname name,
	relname name
);


--
-- Name: TYPE vactables; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TYPE vactables IS 'used as return type for SRF function TablesToVacuum';


--
-- Name: add_empty_table_to_replication(integer, integer, text, text, text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION add_empty_table_to_replication(integer, integer, text, text, text, text) RETURNS bigint
    AS $_$
declare
  p_set_id alias for $1;
  p_tab_id alias for $2;
  p_nspname alias for $3;
  p_tabname alias for $4;
  p_idxname alias for $5;
  p_comment alias for $6;

  prec record;
  v_origin int4;
  v_isorigin boolean;
  v_fqname text;
  v_query text;
  v_rows integer;
  v_idxname text;

begin
-- Need to validate that the set exists; the set will tell us if this is the origin
  select set_origin into v_origin from "_gamersmafia".sl_set where set_id = p_set_id;
  if not found then
	raise exception 'add_empty_table_to_replication: set % not found!', p_set_id;
  end if;

-- Need to be aware of whether or not this node is origin for the set
   v_isorigin := ( v_origin = "_gamersmafia".getLocalNodeId('_gamersmafia') );

   v_fqname := '"' || p_nspname || '"."' || p_tabname || '"';
-- Take out a lock on the table
   v_query := 'lock ' || v_fqname || ';';
   execute v_query;

   if v_isorigin then
	-- On the origin, verify that the table is empty, failing if it has any tuples
        v_query := 'select 1 as tuple from ' || v_fqname || ' limit 1;';
	execute v_query into prec;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
	if v_rows = 0 then
		raise notice 'add_empty_table_to_replication: table % empty on origin - OK', v_fqname;
	else
		raise exception 'add_empty_table_to_replication: table % contained tuples on origin node %', v_fqname, v_origin;
	end if;
   else
	-- On other nodes, TRUNCATE the table
        v_query := 'truncate ' || v_fqname || ';';
	execute v_query;
   end if;
-- If p_idxname is NULL, then look up the PK index, and RAISE EXCEPTION if one does not exist
   if p_idxname is NULL then
	select c2.relname into prec from pg_catalog.pg_index i, pg_catalog.pg_class c1, pg_catalog.pg_class c2, pg_catalog.pg_namespace n where i.indrelid = c1.oid and i.indexrelid = c2.oid and c1.relname = p_tabname and i.indisprimary and n.nspname = p_nspname and n.oid = c1.relnamespace;
	if not found then
		raise exception 'add_empty_table_to_replication: table % has no primary key and no candidate specified!', v_fqname;
	else
		v_idxname := prec.relname;
	end if;
   else
	v_idxname := p_idxname;
   end if;
   return "_gamersmafia".setAddTable_int(p_set_id, p_tab_id, v_fqname, v_idxname, p_comment);
end
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION add_empty_table_to_replication(integer, integer, text, text, text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION add_empty_table_to_replication(integer, integer, text, text, text, text) IS 'Verify that a table is empty, and add it to replication.  
tab_idxname is optional - if NULL, then we use the primary key.';


--
-- Name: add_missing_table_field(text, text, text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION add_missing_table_field(text, text, text, text) RETURNS boolean
    AS $_$
DECLARE
  p_namespace alias for $1;
  p_table     alias for $2;
  p_field     alias for $3;
  p_type      alias for $4;
  v_row       record;
  v_query     text;
BEGIN
  select 1 into v_row from pg_namespace n, pg_class c, pg_attribute a
     where "_gamersmafia".slon_quote_brute(n.nspname) = p_namespace and 
         c.relnamespace = n.oid and
         "_gamersmafia".slon_quote_brute(c.relname) = p_table and
         a.attrelid = c.oid and
         "_gamersmafia".slon_quote_brute(a.attname) = p_field;
  if not found then
    raise notice 'Upgrade table %.% - add field %', p_namespace, p_table, p_field;
    v_query := 'alter table ' || p_namespace || '.' || p_table || ' add column ';
    v_query := v_query || p_field || ' ' || p_type || ';';
    execute v_query;
    return 't';
  else
    return 'f';
  end if;
END;$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION add_missing_table_field(text, text, text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION add_missing_table_field(text, text, text, text) IS 'Add a column of a given type to a table if it is missing';


--
-- Name: addpartiallogindices(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION addpartiallogindices() RETURNS integer
    AS $$
DECLARE
	v_current_status	int4;
	v_log			int4;
	v_dummy		record;
	v_dummy2	record;
	idef 		text;
	v_count		int4;
        v_iname         text;
	v_ilen int4;
	v_maxlen int4;
BEGIN
	v_count := 0;
	select last_value into v_current_status from "_gamersmafia".sl_log_status;

	-- If status is 2 or 3 --> in process of cleanup --> unsafe to create indices
	if v_current_status in (2, 3) then
		return 0;
	end if;

	if v_current_status = 0 then   -- Which log should get indices?
		v_log := 2;
	else
		v_log := 1;
	end if;
--                                       PartInd_test_db_sl_log_2-node-1
	-- Add missing indices...
	for v_dummy in select distinct set_origin from "_gamersmafia".sl_set loop
            v_iname := 'PartInd_gamersmafia_sl_log_' || v_log || '-node-' || v_dummy.set_origin;
	   -- raise notice 'Consider adding partial index % on sl_log_%', v_iname, v_log;
	   -- raise notice 'schema: [_gamersmafia] tablename:[sl_log_%]', v_log;
            select * into v_dummy2 from pg_catalog.pg_indexes where tablename = 'sl_log_' || v_log and  indexname = v_iname;
            if not found then
		-- raise notice 'index was not found - add it!';
        v_iname := 'PartInd_gamersmafia_sl_log_' || v_log || '-node-' || v_dummy.set_origin;
		v_ilen := pg_catalog.length(v_iname);
		v_maxlen := pg_catalog.current_setting('max_identifier_length'::text)::int4;
                if v_ilen > v_maxlen then
		   raise exception 'Length of proposed index name [%] > max_identifier_length [%] - cluster name probably too long', v_ilen, v_maxlen;
		end if;

		idef := 'create index "' || v_iname || 
                        '" on "_gamersmafia".sl_log_' || v_log || ' USING btree(log_txid) where (log_origin = ' || v_dummy.set_origin || ');';
		execute idef;
		v_count := v_count + 1;
            else
                -- raise notice 'Index % already present - skipping', v_iname;
            end if;
	end loop;

	-- Remove unneeded indices...
	for v_dummy in select indexname from pg_catalog.pg_indexes i where i.tablename = 'sl_log_' || v_log and
                       i.indexname like ('PartInd_gamersmafia_sl_log_' || v_log || '-node-%') and
                       not exists (select 1 from "_gamersmafia".sl_set where
				i.indexname = 'PartInd_gamersmafia_sl_log_' || v_log || '-node-' || set_origin)
	loop
		-- raise notice 'Dropping obsolete index %d', v_dummy.indexname;
		idef := 'drop index "_gamersmafia"."' || v_dummy.indexname || '";';
		execute idef;
		v_count := v_count - 1;
	end loop;
	return v_count;
END
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION addpartiallogindices(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION addpartiallogindices() IS 'Add partial indexes, if possible, to the unused sl_log_? table for
all origin nodes, and drop any that are no longer needed.

This function presently gets run any time set origins are manipulated
(FAILOVER, STORE SET, MOVE SET, DROP SET), as well as each time the
system switches between sl_log_1 and sl_log_2.';


--
-- Name: altertableaddtriggers(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION altertableaddtriggers(integer) RETURNS integer
    AS $_$
declare
	p_tab_id			alias for $1;
	v_no_id				int4;
	v_tab_row			record;
	v_tab_fqname		text;
	v_tab_attkind		text;
	v_n					int4;
	v_trec	record;
	v_tgbad	boolean;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get our local node ID
	-- ----
	v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	-- ----
	-- Get the sl_table row and the current origin of the table. 
	-- ----
	select T.tab_reloid, T.tab_set, T.tab_idxname, 
			S.set_origin, PGX.indexrelid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			into v_tab_row
			from "_gamersmafia".sl_table T, "_gamersmafia".sl_set S,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN,
				"pg_catalog".pg_index PGX, "pg_catalog".pg_class PGXC
			where T.tab_id = p_tab_id
				and T.tab_set = S.set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
				and PGX.indrelid = T.tab_reloid
				and PGX.indexrelid = PGXC.oid
				and PGXC.relname = T.tab_idxname
				for update;
	if not found then
		raise exception 'Slony-I: alterTableAddTriggers(): Table with id % not found', p_tab_id;
	end if;
	v_tab_fqname = v_tab_row.tab_fqname;

	v_tab_attkind := "_gamersmafia".determineAttKindUnique(v_tab_row.tab_fqname, 
						v_tab_row.tab_idxname);

	execute 'lock table ' || v_tab_fqname || ' in access exclusive mode';

	-- ----
	-- Create the log and the deny access triggers
	-- ----
	execute 'create trigger "_gamersmafia_logtrigger"' || 
			' after insert or update or delete on ' ||
			v_tab_fqname || ' for each row execute procedure "_gamersmafia".logTrigger (' ||
                               pg_catalog.quote_literal('_gamersmafia') || ',' || 
				pg_catalog.quote_literal(p_tab_id) || ',' || 
				pg_catalog.quote_literal(v_tab_attkind) || ');';

	execute 'create trigger "_gamersmafia_denyaccess" ' || 
			'before insert or update or delete on ' ||
			v_tab_fqname || ' for each row execute procedure ' ||
			'"_gamersmafia".denyAccess (' || pg_catalog.quote_literal('_gamersmafia') || ');';

	perform "_gamersmafia".alterTableConfigureTriggers (p_tab_id);
	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION altertableaddtriggers(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION altertableaddtriggers(integer) IS 'alterTableAddTriggers(tab_id)

Adds the log and deny access triggers to a replicated table.';


--
-- Name: altertableconfiguretriggers(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION altertableconfiguretriggers(integer) RETURNS integer
    AS $_$
declare
	p_tab_id			alias for $1;
	v_no_id				int4;
	v_tab_row			record;
	v_tab_fqname		text;
	v_n					int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get our local node ID
	-- ----
	v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	-- ----
	-- Get the sl_table row and the current tables origin.
	-- ----
	select T.tab_reloid, T.tab_set,
			S.set_origin, PGX.indexrelid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			into v_tab_row
			from "_gamersmafia".sl_table T, "_gamersmafia".sl_set S,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN,
				"pg_catalog".pg_index PGX, "pg_catalog".pg_class PGXC
			where T.tab_id = p_tab_id
				and T.tab_set = S.set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
				and PGX.indrelid = T.tab_reloid
				and PGX.indexrelid = PGXC.oid
				and PGXC.relname = T.tab_idxname
				for update;
	if not found then
		raise exception 'Slony-I: alterTableConfigureTriggers(): Table with id % not found', p_tab_id;
	end if;
	v_tab_fqname = v_tab_row.tab_fqname;

	-- ----
	-- Configuration depends on the origin of the table
	-- ----
	if v_tab_row.set_origin = v_no_id then
		-- ----
		-- On the origin the log trigger is configured like a default
		-- user trigger and the deny access trigger is disabled.
		-- ----
		execute 'alter table ' || v_tab_fqname ||
				' enable trigger "_gamersmafia_logtrigger"';
		execute 'alter table ' || v_tab_fqname ||
				' disable trigger "_gamersmafia_denyaccess"';
	else
		-- ----
		-- On a replica the log trigger is disabled and the
		-- deny access trigger fires in origin session role.
		-- ----
		execute 'alter table ' || v_tab_fqname ||
				' disable trigger "_gamersmafia_logtrigger"';
		execute 'alter table ' || v_tab_fqname ||
				' enable trigger "_gamersmafia_denyaccess"';

	end if;

	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION altertableconfiguretriggers(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION altertableconfiguretriggers(integer) IS 'alterTableConfigureTriggers (tab_id)

Set the enable/disable configuration for the replication triggers
according to the origin of the set.';


--
-- Name: altertabledroptriggers(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION altertabledroptriggers(integer) RETURNS integer
    AS $_$
declare
	p_tab_id			alias for $1;
	v_no_id				int4;
	v_tab_row			record;
	v_tab_fqname		text;
	v_n					int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get our local node ID
	-- ----
	v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	-- ----
	-- Get the sl_table row and the current tables origin.
	-- ----
	select T.tab_reloid, T.tab_set,
			S.set_origin, PGX.indexrelid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			into v_tab_row
			from "_gamersmafia".sl_table T, "_gamersmafia".sl_set S,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN,
				"pg_catalog".pg_index PGX, "pg_catalog".pg_class PGXC
			where T.tab_id = p_tab_id
				and T.tab_set = S.set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
				and PGX.indrelid = T.tab_reloid
				and PGX.indexrelid = PGXC.oid
				and PGXC.relname = T.tab_idxname
				for update;
	if not found then
		raise exception 'Slony-I: alterTableDropTriggers(): Table with id % not found', p_tab_id;
	end if;
	v_tab_fqname = v_tab_row.tab_fqname;

	execute 'lock table ' || v_tab_fqname || ' in access exclusive mode';

	-- ----
	-- Drop both triggers
	-- ----
	execute 'drop trigger "_gamersmafia_logtrigger" on ' || 
			v_tab_fqname;

	execute 'drop trigger "_gamersmafia_denyaccess" on ' || 
			v_tab_fqname;
				
	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION altertabledroptriggers(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION altertabledroptriggers(integer) IS 'alterTableDropTriggers (tab_id)

Remove the log and deny access triggers from a table.';


--
-- Name: altertablerestore(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION altertablerestore(integer) RETURNS integer
    AS $_$
declare
	p_tab_id			alias for $1;
	v_no_id				int4;
	v_tab_row			record;
	v_tab_fqname		text;
	v_n					int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get our local node ID
	-- ----
	v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	-- ----
	-- Get the sl_table row and the current tables origin. Check
	-- that the table currently IS in altered state.
	-- ----
	select T.tab_reloid, T.tab_set, T.tab_altered,
			S.set_origin, PGX.indexrelid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			into v_tab_row
			from "_gamersmafia".sl_table T, "_gamersmafia".sl_set S,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN,
				"pg_catalog".pg_index PGX, "pg_catalog".pg_class PGXC
			where T.tab_id = p_tab_id
				and T.tab_set = S.set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
				and PGX.indrelid = T.tab_reloid
				and PGX.indexrelid = PGXC.oid
				and PGXC.relname = T.tab_idxname
				for update;
	if not found then
		raise exception 'Slony-I: alterTableRestore(): Table with id % not found', p_tab_id;
	end if;
	v_tab_fqname = v_tab_row.tab_fqname;
	if not v_tab_row.tab_altered then
		raise exception 'Slony-I: alterTableRestore(): Table % is not in altered state',
				v_tab_fqname;
	end if;

	execute 'lock table ' || v_tab_fqname || ' in access exclusive mode';

	-- ----
	-- Procedures are different on origin and subscriber
	-- ----
	if v_no_id = v_tab_row.set_origin then
		-- ----
		-- On the Origin we just drop the trigger we originally added
		-- ----
		execute 'drop trigger "_gamersmafia_logtrigger_' || 
				p_tab_id || '" on ' || v_tab_fqname;
	else
		-- ----
		-- On the subscriber drop the denyAccess trigger
		-- ----
		execute 'drop trigger "_gamersmafia_denyaccess_' || 
				p_tab_id || '" on ' || v_tab_fqname;
				
		-- ----
		-- Restore all original triggers
		-- ----
		update "pg_catalog".pg_trigger
				set tgrelid = v_tab_row.tab_reloid
				where tgrelid = v_tab_row.indexrelid;
		get diagnostics v_n = row_count;
		if v_n > 0 then
			update "pg_catalog".pg_class
					set reltriggers = reltriggers + v_n
					where oid = v_tab_row.tab_reloid;
		end if;

		-- ----
		-- Restore all original rewrite rules
		-- ----
		update "pg_catalog".pg_rewrite
				set ev_class = v_tab_row.tab_reloid
				where ev_class = v_tab_row.indexrelid;
		get diagnostics v_n = row_count;
		if v_n > 0 then
			update "pg_catalog".pg_class
					set relhasrules = true
					where oid = v_tab_row.tab_reloid;
		end if;

	end if;

	-- ----
	-- Mark the table not altered in our configuration
	-- ----
	update "_gamersmafia".sl_table
			set tab_altered = false where tab_id = p_tab_id;

	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION altertablerestore(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION altertablerestore(integer) IS 'alterTableRestore (tab_id)

Note: This function only functions properly when used on pre-2.0
systems being converted into 2.0 form.  In Slony-I 2.0, the trigger
handling has changed substantially, such that:

- There are *two* triggers on each table, created at "creation time", and
- There is no need to run "restore" as part of the DDL/EXECUTE SCRIPT process.

Restores table tab_id from being replicated.

On the origin, this simply involves dropping the "logtrigger" trigger.

On subscriber nodes, this involves dropping the "denyaccess" trigger,
and restoring user triggers and rules.';


--
-- Name: checkmoduleversion(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION checkmoduleversion() RETURNS text
    AS $$
declare
  moduleversion	text;
begin
  select into moduleversion "_gamersmafia".getModuleVersion();
  if moduleversion <> '2.0.2' then
      raise exception 'Slonik version: 2.0.2 != Slony-I version in PG build %',
             moduleversion;
  end if;
  return null;
end;$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION checkmoduleversion(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION checkmoduleversion() IS 'Inline test function that verifies that slonik request for STORE
NODE/INIT CLUSTER is being run against a conformant set of
schema/functions.';


--
-- Name: cleanupevent(interval, boolean); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION cleanupevent(interval, boolean) RETURNS integer
    AS $_$
declare
	p_interval alias for $1;
	p_deletelogs alias for $2;
	v_max_row	record;
	v_min_row	record;
	v_max_sync	int8;
	v_origin	int8;
	v_seqno		int8;
	v_xmin		bigint;
	v_rc            int8;
begin
	-- ----
	-- First remove all confirmations where origin/receiver no longer exist
	-- ----
	delete from "_gamersmafia".sl_confirm
				where con_origin not in (select no_id from "_gamersmafia".sl_node);
	delete from "_gamersmafia".sl_confirm
				where con_received not in (select no_id from "_gamersmafia".sl_node);
	-- ----
	-- Next remove all but the oldest confirm row per origin,receiver pair.
	-- Ignore confirmations that are younger than 10 minutes. We currently
	-- have an not confirmed suspicion that a possibly lost transaction due
	-- to a server crash might have been visible to another session, and
	-- that this led to log data that is needed again got removed.
	-- ----
	for v_max_row in select con_origin, con_received, max(con_seqno) as con_seqno
				from "_gamersmafia".sl_confirm
				where con_timestamp < (CURRENT_TIMESTAMP - p_interval)
				group by con_origin, con_received
	loop
		delete from "_gamersmafia".sl_confirm
				where con_origin = v_max_row.con_origin
				and con_received = v_max_row.con_received
				and con_seqno < v_max_row.con_seqno;
	end loop;

	-- ----
	-- Then remove all events that are confirmed by all nodes in the
	-- whole cluster up to the last SYNC
	-- ----
	for v_min_row in select con_origin, min(con_seqno) as con_seqno
				from "_gamersmafia".sl_confirm
				group by con_origin
	loop
		select coalesce(max(ev_seqno), 0) into v_max_sync
				from "_gamersmafia".sl_event
				where ev_origin = v_min_row.con_origin
				and ev_seqno <= v_min_row.con_seqno
				and ev_type = 'SYNC';
		if v_max_sync > 0 then
			delete from "_gamersmafia".sl_event
					where ev_origin = v_min_row.con_origin
					and ev_seqno < v_max_sync;
		end if;
	end loop;

	-- ----
	-- If cluster has only one node, then remove all events up to
	-- the last SYNC - Bug #1538
        -- http://gborg.postgresql.org/project/slony1/bugs/bugupdate.php?1538
	-- ----

	select * into v_min_row from "_gamersmafia".sl_node where
			no_id <> "_gamersmafia".getLocalNodeId('_gamersmafia') limit 1;
	if not found then
		select ev_origin, ev_seqno into v_min_row from "_gamersmafia".sl_event
		where ev_origin = "_gamersmafia".getLocalNodeId('_gamersmafia')
		order by ev_origin desc, ev_seqno desc limit 1;
		raise notice 'Slony-I: cleanupEvent(): Single node - deleting events < %', v_min_row.ev_seqno;
			delete from "_gamersmafia".sl_event
			where
				ev_origin = v_min_row.ev_origin and
				ev_seqno < v_min_row.ev_seqno;

        end if;

	if exists (select * from "pg_catalog".pg_class c, "pg_catalog".pg_namespace n, "pg_catalog".pg_attribute a where c.relname = 'sl_seqlog' and n.oid = c.relnamespace and a.attrelid = c.oid and a.attname = 'oid') then
                execute 'alter table "_gamersmafia".sl_seqlog set without oids;';
	end if;		
	-- ----
	-- Also remove stale entries from the nodelock table.
	-- ----
	perform "_gamersmafia".cleanupNodelock();

	-- ----
	-- Find the eldest event left, for each origin
	-- ----
        for v_origin, v_seqno, v_xmin in
	  select ev_origin, ev_seqno, "pg_catalog".txid_snapshot_xmin(ev_snapshot) from "_gamersmafia".sl_event
          where (ev_origin, ev_seqno) in (select ev_origin, min(ev_seqno) from "_gamersmafia".sl_event where ev_type = 'SYNC' group by ev_origin)
	loop
		if p_deletelogs then
			delete from "_gamersmafia".sl_log_1 where log_origin = v_origin and log_txid < v_xmin;		
			delete from "_gamersmafia".sl_log_2 where log_origin = v_origin and log_txid < v_xmin;		
		end if;
		delete from "_gamersmafia".sl_seqlog where seql_origin = v_origin and seql_ev_seqno < v_seqno;
        end loop;
	
	v_rc := "_gamersmafia".logswitch_finish();
	if v_rc = 0 then   -- no switch in progress
		perform "_gamersmafia".logswitch_start();
	end if;

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION cleanupevent(interval, boolean); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION cleanupevent(interval, boolean) IS 'cleaning old data out of sl_confirm, sl_event.  Removes all but the
last sl_confirm row per (origin,receiver), and then removes all events
that are confirmed by all nodes in the whole cluster up to the last
SYNC.  Deletes now-orphaned entries from sl_log_* if delete_logs parameter is set';


--
-- Name: cleanupnodelock(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION cleanupnodelock() RETURNS integer
    AS $$
declare
	v_row		record;
begin
	for v_row in select nl_nodeid, nl_conncnt, nl_backendpid
			from "_gamersmafia".sl_nodelock
			for update
	loop
		if "_gamersmafia".killBackend(v_row.nl_backendpid, 'NULL') < 0 then
			raise notice 'Slony-I: cleanup stale sl_nodelock entry for pid=%',
					v_row.nl_backendpid;
			delete from "_gamersmafia".sl_nodelock where
					nl_nodeid = v_row.nl_nodeid and
					nl_conncnt = v_row.nl_conncnt;
		end if;
	end loop;

	return 0;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION cleanupnodelock(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION cleanupnodelock() IS 'Clean up stale entries when restarting slon';


--
-- Name: clonenodefinish(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION clonenodefinish(integer, integer) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	p_no_provider	alias for $2;
	v_row			record;
begin
	perform "pg_catalog".setval('"_gamersmafia".sl_local_node_id', p_no_id);

	for v_row in select sub_set from "_gamersmafia".sl_subscribe
			where sub_receiver = p_no_id
	loop
		perform "_gamersmafia".updateReloid(v_row.sub_set, p_no_id);
	end loop;

	perform "_gamersmafia".RebuildListenEntries();

	delete from "_gamersmafia".sl_confirm
		where con_received = p_no_id;
	insert into "_gamersmafia".sl_confirm
		(con_origin, con_received, con_seqno, con_timestamp)
		select con_origin, p_no_id, con_seqno, con_timestamp
		from "_gamersmafia".sl_confirm
		where con_received = p_no_provider;
	insert into "_gamersmafia".sl_confirm
		(con_origin, con_received, con_seqno, con_timestamp)
		select p_no_provider, p_no_id, 
				(select max(ev_seqno) from "_gamersmafia".sl_event
					where ev_origin = p_no_provider), current_timestamp;

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION clonenodefinish(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION clonenodefinish(integer, integer) IS 'Internal part of cloneNodePrepare().';


--
-- Name: clonenodeprepare(integer, integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION clonenodeprepare(integer, integer, text) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	p_no_provider	alias for $2;
	p_no_comment	alias for $3;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	perform "_gamersmafia".cloneNodePrepare_int (p_no_id, p_no_provider, p_no_comment);
	return  "_gamersmafia".createEvent('_gamersmafia', 'CLONE_NODE',
									p_no_id::text, p_no_provider::text,
									p_no_comment::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION clonenodeprepare(integer, integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION clonenodeprepare(integer, integer, text) IS 'Prepare for cloning a node.';


--
-- Name: clonenodeprepare_int(integer, integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION clonenodeprepare_int(integer, integer, text) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	p_no_provider	alias for $2;
	p_no_comment	alias for $3;
begin
	insert into "_gamersmafia".sl_node
		(no_id, no_active, no_comment)
		select p_no_id, no_active, p_no_comment
		from "_gamersmafia".sl_node
		where no_id = p_no_provider;

	insert into "_gamersmafia".sl_path
		(pa_server, pa_client, pa_conninfo, pa_connretry)
		select pa_server, p_no_id, 'Event pending', pa_connretry
		from "_gamersmafia".sl_path
		where pa_client = p_no_provider;
	insert into "_gamersmafia".sl_path
		(pa_server, pa_client, pa_conninfo, pa_connretry)
		select p_no_id, pa_client, 'Event pending', pa_connretry
		from "_gamersmafia".sl_path
		where pa_server = p_no_provider;

	insert into "_gamersmafia".sl_subscribe
		(sub_set, sub_provider, sub_receiver, sub_forward, sub_active)
		select sub_set, sub_provider, p_no_id, sub_forward, sub_active
		from "_gamersmafia".sl_subscribe
		where sub_receiver = p_no_provider;

	insert into "_gamersmafia".sl_confirm
		(con_origin, con_received, con_seqno, con_timestamp)
		select con_origin, p_no_id, con_seqno, con_timestamp
		from "_gamersmafia".sl_confirm
		where con_received = p_no_provider;

	perform "_gamersmafia".RebuildListenEntries();

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION clonenodeprepare_int(integer, integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION clonenodeprepare_int(integer, integer, text) IS 'Internal part of cloneNodePrepare().';


--
-- Name: copyfields(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION copyfields(integer) RETURNS text
    AS $_$
declare
	result text;
	prefix text;
	prec record;
begin
	result := '';
	prefix := '(';   -- Initially, prefix is the opening paren

	for prec in select "_gamersmafia".slon_quote_input(a.attname) as column from "_gamersmafia".sl_table t, pg_catalog.pg_attribute a where t.tab_id = $1 and t.tab_reloid = a.attrelid and a.attnum > 0 and a.attisdropped = false order by attnum
	loop
		result := result || prefix || prec.column;
		prefix := ',';   -- Subsequently, prepend columns with commas
	end loop;
	result := result || ')';
	return result;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION copyfields(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION copyfields(integer) IS 'Return a string consisting of what should be appended to a COPY statement
to specify fields for the passed-in tab_id.  

In PG versions > 7.3, this looks like (field1,field2,...fieldn)';


--
-- Name: ddlscript_complete(integer, text, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION ddlscript_complete(integer, text, integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_script			alias for $2;
	p_only_on_node		alias for $3;
	v_set_origin		int4;
begin
	perform "_gamersmafia".updateRelname(p_set_id, p_only_on_node);
	if p_only_on_node = -1 then
		return  "_gamersmafia".createEvent('_gamersmafia', 'DDL_SCRIPT', 
			p_set_id::text, p_script::text, p_only_on_node::text);
	end if;
	return NULL;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION ddlscript_complete(integer, text, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION ddlscript_complete(integer, text, integer) IS 'ddlScript_complete(set_id, script, only_on_node)

After script has run on origin, this fixes up relnames, restores
triggers, and generates a DDL_SCRIPT event to request it to be run on
replicated slaves.';


--
-- Name: ddlscript_complete_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION ddlscript_complete_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_only_on_node		alias for $2;
	v_row				record;
begin
	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION ddlscript_complete_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION ddlscript_complete_int(integer, integer) IS 'ddlScript_complete_int(set_id, script, only_on_node)

Complete processing the DDL_SCRIPT event.  This puts tables back into
replicated mode.';


--
-- Name: ddlscript_prepare(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION ddlscript_prepare(integer, integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_only_on_node		alias for $2;
	v_set_origin		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that the set exists and originates here
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if p_only_on_node = -1 then
		if v_set_origin <> "_gamersmafia".getLocalNodeId('_gamersmafia') then
			raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
		end if;
		-- ----
		-- Create a SYNC event
		-- ----
		perform "_gamersmafia".createEvent('_gamersmafia', 'SYNC', NULL);
	else
		-- If running "ONLY ON NODE", there are two possibilities:
		-- 1.  Running on origin, where denyaccess() triggers are already shut off
		-- 2.  Running on replica, where we need the LOCAL role to suppress denyaccess() triggers
		if (v_set_origin <> "_gamersmafia".getLocalNodeId('_gamersmafia')) then
			execute 'set session_replication_role to local;';
		end if;
	end if;
	return 1;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION ddlscript_prepare(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION ddlscript_prepare(integer, integer) IS 'Prepare for DDL script execution on origin';


--
-- Name: ddlscript_prepare_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION ddlscript_prepare_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_only_on_node		alias for $2;
	v_set_origin		int4;
	v_no_id				int4;
	v_row				record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that we either are the set origin or a current
	-- subscriber of the set.
	-- ----
	v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_set_origin <> v_no_id
			and not exists (select 1 from "_gamersmafia".sl_subscribe
						where sub_set = p_set_id
						and sub_receiver = v_no_id)
	then
		return 0;
	end if;

	-- ----
	-- If execution on only one node is requested, check that
	-- we are that node.
	-- ----
	if p_only_on_node > 0 and p_only_on_node <> v_no_id then
		return 0;
	end if;

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION ddlscript_prepare_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION ddlscript_prepare_int(integer, integer) IS 'ddlScript_prepare_int (set_id, only_on_node)

Do preparatory work for a DDL script, restoring 
triggers/rules to original state.';


--
-- Name: determineattkindunique(text, name); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION determineattkindunique(text, name) RETURNS text
    AS $_$
declare
	p_tab_fqname	alias for $1;
	v_tab_fqname_quoted	text default '';
	p_idx_name		alias for $2;
	v_idx_name_quoted	text;
	v_idxrow		record;
	v_attrow		record;
	v_i				integer;
	v_attno			int2;
	v_attkind		text default '';
	v_attfound		bool;
begin
	v_tab_fqname_quoted := "_gamersmafia".slon_quote_input(p_tab_fqname);
	v_idx_name_quoted := "_gamersmafia".slon_quote_brute(p_idx_name);
	--
	-- Ensure that the table exists
	--
	if (select PGC.relname
				from "pg_catalog".pg_class PGC,
					"pg_catalog".pg_namespace PGN
				where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
					"_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
					and PGN.oid = PGC.relnamespace) is null then
		raise exception 'Slony-I: table % not found', v_tab_fqname_quoted;
	end if;

	--
	-- Lookup the tables primary key or the specified unique index
	--
	if p_idx_name isnull then
		raise exception 'Slony-I: index name must be specified';
	else
		select PGXC.relname, PGX.indexrelid, PGX.indkey
				into v_idxrow
				from "pg_catalog".pg_class PGC,
					"pg_catalog".pg_namespace PGN,
					"pg_catalog".pg_index PGX,
					"pg_catalog".pg_class PGXC
				where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
					"_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
					and PGN.oid = PGC.relnamespace
					and PGX.indrelid = PGC.oid
					and PGX.indexrelid = PGXC.oid
					and PGX.indisunique
					and "_gamersmafia".slon_quote_brute(PGXC.relname) = v_idx_name_quoted;
		if not found then
			raise exception 'Slony-I: table % has no unique index %',
					v_tab_fqname_quoted, v_idx_name_quoted;
		end if;
	end if;

	--
	-- Loop over the tables attributes and check if they are
	-- index attributes. If so, add a "k" to the return value,
	-- otherwise add a "v".
	--
	for v_attrow in select PGA.attnum, PGA.attname
			from "pg_catalog".pg_class PGC,
			    "pg_catalog".pg_namespace PGN,
				"pg_catalog".pg_attribute PGA
			where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			    "_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
				and PGN.oid = PGC.relnamespace
				and PGA.attrelid = PGC.oid
				and not PGA.attisdropped
				and PGA.attnum > 0
			order by attnum
	loop
		v_attfound = 'f';

		v_i := 0;
		loop
			select indkey[v_i] into v_attno from "pg_catalog".pg_index
					where indexrelid = v_idxrow.indexrelid;
			if v_attno isnull or v_attno = 0 then
				exit;
			end if;
			if v_attrow.attnum = v_attno then
				v_attfound = 't';
				exit;
			end if;
			v_i := v_i + 1;
		end loop;

		if v_attfound then
			v_attkind := v_attkind || 'k';
		else
			v_attkind := v_attkind || 'v';
		end if;
	end loop;

	-- Strip off trailing v characters as they are not needed by the logtrigger
	v_attkind := pg_catalog.rtrim(v_attkind, 'v');

	--
	-- Return the resulting attkind
	--
	return v_attkind;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION determineattkindunique(text, name); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION determineattkindunique(text, name) IS 'determineAttKindUnique (tab_fqname, indexname)

Given a tablename, return the Slony-I specific attkind (used for the
log trigger) of the table. Use the specified unique index or the
primary key (if indexname is NULL).';


--
-- Name: determineidxnameunique(text, name); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION determineidxnameunique(text, name) RETURNS name
    AS $_$
declare
	p_tab_fqname	alias for $1;
	v_tab_fqname_quoted	text default '';
	p_idx_name		alias for $2;
	v_idxrow		record;
begin
	v_tab_fqname_quoted := "_gamersmafia".slon_quote_input(p_tab_fqname);
	--
	-- Ensure that the table exists
	--
	if (select PGC.relname
				from "pg_catalog".pg_class PGC,
					"pg_catalog".pg_namespace PGN
				where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
					"_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
					and PGN.oid = PGC.relnamespace) is null then
		raise exception 'Slony-I: determineIdxnameUnique(): table % not found', v_tab_fqname_quoted;
	end if;

	--
	-- Lookup the tables primary key or the specified unique index
	--
	if p_idx_name isnull then
		select PGXC.relname
				into v_idxrow
				from "pg_catalog".pg_class PGC,
					"pg_catalog".pg_namespace PGN,
					"pg_catalog".pg_index PGX,
					"pg_catalog".pg_class PGXC
				where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
					"_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
					and PGN.oid = PGC.relnamespace
					and PGX.indrelid = PGC.oid
					and PGX.indexrelid = PGXC.oid
					and PGX.indisprimary;
		if not found then
			raise exception 'Slony-I: table % has no primary key',
					v_tab_fqname_quoted;
		end if;
	else
		select PGXC.relname
				into v_idxrow
				from "pg_catalog".pg_class PGC,
					"pg_catalog".pg_namespace PGN,
					"pg_catalog".pg_index PGX,
					"pg_catalog".pg_class PGXC
				where "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
					"_gamersmafia".slon_quote_brute(PGC.relname) = v_tab_fqname_quoted
					and PGN.oid = PGC.relnamespace
					and PGX.indrelid = PGC.oid
					and PGX.indexrelid = PGXC.oid
					and PGX.indisunique
					and "_gamersmafia".slon_quote_brute(PGXC.relname) = "_gamersmafia".slon_quote_input(p_idx_name);
		if not found then
			raise exception 'Slony-I: table % has no unique index %',
					v_tab_fqname_quoted, p_idx_name;
		end if;
	end if;

	--
	-- Return the found index name
	--
	return v_idxrow.relname;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION determineidxnameunique(text, name); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION determineidxnameunique(text, name) IS 'FUNCTION determineIdxnameUnique (tab_fqname, indexname)

Given a tablename, tab_fqname, check that the unique index, indexname,
exists or return the primary key index name for the table.  If there
is no unique index, it raises an exception.';


--
-- Name: disablenode(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION disablenode(integer) RETURNS bigint
    AS $_$
declare
	p_no_id			alias for $1;
begin
	-- **** TODO ****
	raise exception 'Slony-I: disableNode() not implemented';
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION disablenode(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION disablenode(integer) IS 'process DISABLE_NODE event for node no_id

NOTE: This is not yet implemented!';


--
-- Name: disablenode_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION disablenode_int(integer) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
begin
	-- **** TODO ****
	raise exception 'Slony-I: disableNode_int() not implemented';
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: droplisten(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION droplisten(integer, integer, integer) RETURNS bigint
    AS $_$
declare
	p_li_origin		alias for $1;
	p_li_provider	alias for $2;
	p_li_receiver	alias for $3;
begin
	perform "_gamersmafia".dropListen_int(p_li_origin, 
			p_li_provider, p_li_receiver);
	
	return  "_gamersmafia".createEvent ('_gamersmafia', 'DROP_LISTEN',
			p_li_origin::text, p_li_provider::text, p_li_receiver::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION droplisten(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION droplisten(integer, integer, integer) IS 'dropListen (li_origin, li_provider, li_receiver)

Generate the DROP_LISTEN event.';


--
-- Name: droplisten_int(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION droplisten_int(integer, integer, integer) RETURNS integer
    AS $_$
declare
	p_li_origin		alias for $1;
	p_li_provider	alias for $2;
	p_li_receiver	alias for $3;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	delete from "_gamersmafia".sl_listen
			where li_origin = p_li_origin
			and li_provider = p_li_provider
			and li_receiver = p_li_receiver;
	if found then
		return 1;
	else
		return 0;
	end if;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION droplisten_int(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION droplisten_int(integer, integer, integer) IS 'dropListen (li_origin, li_provider, li_receiver)

Process the DROP_LISTEN event, deleting the sl_listen entry for
the indicated (origin,provider,receiver) combination.';


--
-- Name: dropnode(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION dropnode(integer) RETURNS bigint
    AS $_$
declare
	p_no_id			alias for $1;
	v_node_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that this got called on a different node
	-- ----
	if p_no_id = "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: DROP_NODE cannot initiate on the dropped node';
	end if;

	select * into v_node_row from "_gamersmafia".sl_node
			where no_id = p_no_id
			for update;
	if not found then
		raise exception 'Slony-I: unknown node ID %', p_no_id;
	end if;

	-- ----
	-- Make sure we do not break other nodes subscriptions with this
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe
			where sub_provider = p_no_id)
	then
		raise exception 'Slony-I: Node % is still configured as a data provider',
				p_no_id;
	end if;

	-- ----
	-- Make sure no set originates there any more
	-- ----
	if exists (select true from "_gamersmafia".sl_set
			where set_origin = p_no_id)
	then
		raise exception 'Slony-I: Node % is still origin of one or more sets',
				p_no_id;
	end if;

	-- ----
	-- Call the internal drop functionality and generate the event
	-- ----
	perform "_gamersmafia".dropNode_int(p_no_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'DROP_NODE',
									p_no_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION dropnode(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION dropnode(integer) IS 'generate DROP_NODE event to drop node node_id from replication';


--
-- Name: dropnode_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION dropnode_int(integer) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	v_tab_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- If the dropped node is a remote node, clean the configuration
	-- from all traces for it.
	-- ----
	if p_no_id <> "_gamersmafia".getLocalNodeId('_gamersmafia') then
		delete from "_gamersmafia".sl_subscribe
				where sub_receiver = p_no_id;
		delete from "_gamersmafia".sl_listen
				where li_origin = p_no_id
					or li_provider = p_no_id
					or li_receiver = p_no_id;
		delete from "_gamersmafia".sl_path
				where pa_server = p_no_id
					or pa_client = p_no_id;
		delete from "_gamersmafia".sl_confirm
				where con_origin = p_no_id
					or con_received = p_no_id;
		delete from "_gamersmafia".sl_event
				where ev_origin = p_no_id;
		delete from "_gamersmafia".sl_node
				where no_id = p_no_id;

		return p_no_id;
	end if;

	-- ----
	-- This is us ... deactivate the node for now, the daemon
	-- will call uninstallNode() in a separate transaction.
	-- ----
	update "_gamersmafia".sl_node
			set no_active = false
			where no_id = p_no_id;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	return p_no_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION dropnode_int(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION dropnode_int(integer) IS 'internal function to process DROP_NODE event to drop node node_id from replication';


--
-- Name: droppath(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION droppath(integer, integer) RETURNS bigint
    AS $_$
declare
	p_pa_server		alias for $1;
	p_pa_client		alias for $2;
	v_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- There should be no existing subscriptions. Auto unsubscribing
	-- is considered too dangerous. 
	-- ----
	for v_row in select sub_set, sub_provider, sub_receiver
			from "_gamersmafia".sl_subscribe
			where sub_provider = p_pa_server
			and sub_receiver = p_pa_client
	loop
		raise exception 
			'Slony-I: Path cannot be dropped, subscription of set % needs it',
			v_row.sub_set;
	end loop;

	-- ----
	-- Drop all sl_listen entries that depend on this path
	-- ----
	for v_row in select li_origin, li_provider, li_receiver
			from "_gamersmafia".sl_listen
			where li_provider = p_pa_server
			and li_receiver = p_pa_client
	loop
		perform "_gamersmafia".dropListen(
				v_row.li_origin, v_row.li_provider, v_row.li_receiver);
	end loop;

	-- ----
	-- Now drop the path and create the event
	-- ----
	perform "_gamersmafia".dropPath_int(p_pa_server, p_pa_client);

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	return  "_gamersmafia".createEvent ('_gamersmafia', 'DROP_PATH',
			p_pa_server::text, p_pa_client::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION droppath(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION droppath(integer, integer) IS 'Generate DROP_PATH event to drop path from pa_server to pa_client';


--
-- Name: droppath_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION droppath_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_pa_server		alias for $1;
	p_pa_client		alias for $2;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Remove any dangling sl_listen entries with the server
	-- as provider and the client as receiver. This must have
	-- been cleared out before, but obviously was not.
	-- ----
	delete from "_gamersmafia".sl_listen
			where li_provider = p_pa_server
			and li_receiver = p_pa_client;

	delete from "_gamersmafia".sl_path
			where pa_server = p_pa_server
			and pa_client = p_pa_client;

	if found then
		-- Rewrite sl_listen table
		perform "_gamersmafia".RebuildListenEntries();

		return 1;
	else
		-- Rewrite sl_listen table
		perform "_gamersmafia".RebuildListenEntries();

		return 0;
	end if;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION droppath_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION droppath_int(integer, integer) IS 'Process DROP_PATH event to drop path from pa_server to pa_client';


--
-- Name: dropset(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION dropset(integer) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	v_origin			int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	-- ----
	-- Check that the set exists and originates here
	-- ----
	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
	end if;

	-- ----
	-- Call the internal drop set functionality and generate the event
	-- ----
	perform "_gamersmafia".dropSet_int(p_set_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'DROP_SET', 
			p_set_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION dropset(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION dropset(integer) IS 'Process DROP_SET event to drop replication of set set_id.  This involves:
- Removing log and deny access triggers
- Removing all traces of the set configuration, including sequences, tables, subscribers, syncs, and the set itself';


--
-- Name: dropset_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION dropset_int(integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	v_tab_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	-- ----
	-- Restore all tables original triggers and rules and remove
	-- our replication stuff.
	-- ----
	for v_tab_row in select tab_id from "_gamersmafia".sl_table
			where tab_set = p_set_id
			order by tab_id
	loop
		perform "_gamersmafia".alterTableDropTriggers(v_tab_row.tab_id);
	end loop;

	-- ----
	-- Remove all traces of the set configuration
	-- ----
	delete from "_gamersmafia".sl_sequence
			where seq_set = p_set_id;
	delete from "_gamersmafia".sl_table
			where tab_set = p_set_id;
	delete from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id;
	delete from "_gamersmafia".sl_setsync
			where ssy_setid = p_set_id;
	delete from "_gamersmafia".sl_set
			where set_id = p_set_id;

	-- Regenerate sl_listen since we revised the subscriptions
	perform "_gamersmafia".RebuildListenEntries();

	-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
	perform "_gamersmafia".addPartialLogIndices();

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: enablenode(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION enablenode(integer) RETURNS bigint
    AS $_$
declare
	p_no_id			alias for $1;
	v_local_node_id	int4;
	v_node_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that we are the node to activate and that we are
	-- currently disabled.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select * into v_node_row
			from "_gamersmafia".sl_node
			where no_id = p_no_id
			for update;
	if not found then 
		raise exception 'Slony-I: node % not found', p_no_id;
	end if;
	if v_node_row.no_active then
		raise exception 'Slony-I: node % is already active', p_no_id;
	end if;

	-- ----
	-- Activate this node and generate the ENABLE_NODE event
	-- ----
	perform "_gamersmafia".enableNode_int (p_no_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'ENABLE_NODE',
									p_no_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION enablenode(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION enablenode(integer) IS 'no_id - Node ID #

Generate the ENABLE_NODE event for node no_id';


--
-- Name: enablenode_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION enablenode_int(integer) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	v_local_node_id	int4;
	v_node_row		record;
	v_sub_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that the node is inactive
	-- ----
	select * into v_node_row
			from "_gamersmafia".sl_node
			where no_id = p_no_id
			for update;
	if not found then 
		raise exception 'Slony-I: node % not found', p_no_id;
	end if;
	if v_node_row.no_active then
		return p_no_id;
	end if;

	-- ----
	-- Activate the node and generate sl_confirm status rows for it.
	-- ----
	update "_gamersmafia".sl_node
			set no_active = 't'
			where no_id = p_no_id;
	insert into "_gamersmafia".sl_confirm
			(con_origin, con_received, con_seqno)
			select no_id, p_no_id, 0 from "_gamersmafia".sl_node
				where no_id != p_no_id
				and no_active;
	insert into "_gamersmafia".sl_confirm
			(con_origin, con_received, con_seqno)
			select p_no_id, no_id, 0 from "_gamersmafia".sl_node
				where no_id != p_no_id
				and no_active;

	-- ----
	-- Generate ENABLE_SUBSCRIPTION events for all sets that
	-- origin here and are subscribed by the just enabled node.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	for v_sub_row in select SUB.sub_set, SUB.sub_provider from
			"_gamersmafia".sl_set S,
			"_gamersmafia".sl_subscribe SUB
			where S.set_origin = v_local_node_id
			and S.set_id = SUB.sub_set
			and SUB.sub_receiver = p_no_id
			for update of S
	loop
		perform "_gamersmafia".enableSubscription (v_sub_row.sub_set,
				v_sub_row.sub_provider, p_no_id);
	end loop;

	return p_no_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION enablenode_int(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION enablenode_int(integer) IS 'no_id - Node ID #

Internal function to process the ENABLE_NODE event for node no_id';


--
-- Name: enablesubscription(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION enablesubscription(integer, integer, integer) RETURNS integer
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_provider		alias for $2;
	p_sub_receiver		alias for $3;
begin
	return  "_gamersmafia".enableSubscription_int (p_sub_set, 
			p_sub_provider, p_sub_receiver);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION enablesubscription(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION enablesubscription(integer, integer, integer) IS 'enableSubscription (sub_set, sub_provider, sub_receiver)

Indicates that sub_receiver intends subscribing to set sub_set from
sub_provider.  Work is all done by the internal function
enableSubscription_int (sub_set, sub_provider, sub_receiver).';


--
-- Name: enablesubscription_int(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION enablesubscription_int(integer, integer, integer) RETURNS integer
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_provider		alias for $2;
	p_sub_receiver		alias for $3;
	v_n					int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- The real work is done in the replication engine. All
	-- we have to do here is remembering that it happened.
	-- ----

	-- ----
	-- Well, not only ... we might be missing an important event here
	-- ----
	if not exists (select true from "_gamersmafia".sl_path
			where pa_server = p_sub_provider
			and pa_client = p_sub_receiver)
	then
		insert into "_gamersmafia".sl_path
				(pa_server, pa_client, pa_conninfo, pa_connretry)
				values 
				(p_sub_provider, p_sub_receiver, 
				'<event pending>', 10);
	end if;

	update "_gamersmafia".sl_subscribe
			set sub_active = 't'
			where sub_set = p_sub_set
			and sub_receiver = p_sub_receiver;
	get diagnostics v_n = row_count;
	if v_n = 0 then
		insert into "_gamersmafia".sl_subscribe
				(sub_set, sub_provider, sub_receiver,
				sub_forward, sub_active)
				values
				(p_sub_set, p_sub_provider, p_sub_receiver,
				false, true);
	end if;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	return p_sub_set;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION enablesubscription_int(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION enablesubscription_int(integer, integer, integer) IS 'enableSubscription_int (sub_set, sub_provider, sub_receiver)

Internal function to enable subscription of node sub_receiver to set
sub_set via node sub_provider.

slon does most of the work; all we need do here is to remember that it
happened.  The function updates sl_subscribe, indicating that the
subscription has become active.';


--
-- Name: failednode(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION failednode(integer, integer) RETURNS integer
    AS $_$
declare
	p_failed_node		alias for $1;
	p_backup_node		alias for $2;
	v_row				record;
	v_row2				record;
	v_n					int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- All consistency checks first
	-- Check that every node that has a path to the failed node
	-- also has a path to the backup node.
	-- ----
	for v_row in select P.pa_client
			from "_gamersmafia".sl_path P
			where P.pa_server = p_failed_node
				and P.pa_client <> p_backup_node
				and not exists (select true from "_gamersmafia".sl_path PP
							where PP.pa_server = p_backup_node
								and PP.pa_client = P.pa_client)
	loop
		raise exception 'Slony-I: cannot failover - node % has no path to the backup node',
				v_row.pa_client;
	end loop;

	-- ----
	-- Check all sets originating on the failed node
	-- ----
	for v_row in select set_id
			from "_gamersmafia".sl_set
			where set_origin = p_failed_node
	loop
		-- ----
		-- Check that the backup node is subscribed to all sets
		-- that originate on the failed node
		-- ----
		select into v_row2 sub_forward, sub_active
				from "_gamersmafia".sl_subscribe
				where sub_set = v_row.set_id
					and sub_receiver = p_backup_node;
		if not found then
			raise exception 'Slony-I: cannot failover - node % is not subscribed to set %',
					p_backup_node, v_row.set_id;
		end if;

		-- ----
		-- Check that the subscription is active
		-- ----
		if not v_row2.sub_active then
			raise exception 'Slony-I: cannot failover - subscription for set % is not active',
					v_row.set_id;
		end if;

		-- ----
		-- If there are other subscribers, the backup node needs to
		-- be a forwarder too.
		-- ----
		select into v_n count(*)
				from "_gamersmafia".sl_subscribe
				where sub_set = v_row.set_id
					and sub_receiver <> p_backup_node;
		if v_n > 0 and not v_row2.sub_forward then
			raise exception 'Slony-I: cannot failover - node % is not a forwarder of set %',
					p_backup_node, v_row.set_id;
		end if;
	end loop;

	-- ----
	-- Terminate all connections of the failed node the hard way
	-- ----
	perform "_gamersmafia".terminateNodeConnections(p_failed_node);

	-- ----
	-- Move the sets
	-- ----
	for v_row in select S.set_id, (select count(*)
					from "_gamersmafia".sl_subscribe SUB
					where S.set_id = SUB.sub_set
						and SUB.sub_receiver <> p_backup_node
						and SUB.sub_provider = p_failed_node)
					as num_direct_receivers 
			from "_gamersmafia".sl_set S
			where S.set_origin = p_failed_node
			for update
	loop
		-- ----
		-- If the backup node is the only direct subscriber ...
		-- ----
		if v_row.num_direct_receivers = 0 then
		        raise notice 'failedNode: set % has no other direct receivers - move now', v_row.set_id;
			-- ----
			-- backup_node is the only direct subscriber, move the set
			-- right now. On the backup node itself that includes restoring
			-- all user mode triggers, removing the protection trigger,
			-- adding the log trigger, removing the subscription and the
			-- obsolete setsync status.
			-- ----
			if p_backup_node = "_gamersmafia".getLocalNodeId('_gamersmafia') then
				update "_gamersmafia".sl_set set set_origin = p_backup_node
						where set_id = v_row.set_id;

				delete from "_gamersmafia".sl_setsync
						where ssy_setid = v_row.set_id;

				for v_row2 in select * from "_gamersmafia".sl_table
						where tab_set = v_row.set_id
						order by tab_id
				loop
					perform "_gamersmafia".alterTableConfigureTriggers(v_row2.tab_id);
				end loop;
			end if;

			delete from "_gamersmafia".sl_subscribe
					where sub_set = v_row.set_id
						and sub_receiver = p_backup_node;
		else
			raise notice 'failedNode: set % has other direct receivers - change providers only', v_row.set_id;
			-- ----
			-- Backup node is not the only direct subscriber. This
			-- means that at this moment, we redirect all direct
			-- subscribers to receive from the backup node, and the
			-- backup node itself to receive from another one.
			-- The admin utility will wait for the slon engine to
			-- restart and then call failedNode2() on the node with
			-- the highest SYNC and redirect this to it on
			-- backup node later.
			-- ----
			update "_gamersmafia".sl_subscribe
					set sub_provider = (select min(SS.sub_receiver)
							from "_gamersmafia".sl_subscribe SS
							where SS.sub_set = v_row.set_id
								and SS.sub_provider = p_failed_node
								and SS.sub_receiver <> p_backup_node
								and SS.sub_forward)
					where sub_set = v_row.set_id
						and sub_receiver = p_backup_node;
			update "_gamersmafia".sl_subscribe
					set sub_provider = p_backup_node
					where sub_set = v_row.set_id
						and sub_provider = p_failed_node
						and sub_receiver <> p_backup_node;
		end if;
	end loop;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
	perform "_gamersmafia".addPartialLogIndices();

	-- ----
	-- Make sure the node daemon will restart
	-- ----
	notify "_gamersmafia_Restart";

	-- ----
	-- That is it - so far.
	-- ----
	return p_failed_node;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION failednode(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION failednode(integer, integer) IS 'Initiate failover from failed_node to backup_node.  This function must be called on all nodes, 
and then waited for the restart of all node daemons.';


--
-- Name: failednode2(integer, integer, integer, bigint, bigint); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION failednode2(integer, integer, integer, bigint, bigint) RETURNS bigint
    AS $_$
declare
	p_failed_node		alias for $1;
	p_backup_node		alias for $2;
	p_set_id			alias for $3;
	p_ev_seqno			alias for $4;
	p_ev_seqfake		alias for $5;
	v_row				record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	select * into v_row
			from "_gamersmafia".sl_event
			where ev_origin = p_failed_node
			and ev_seqno = p_ev_seqno;
	if not found then
		raise exception 'Slony-I: event %,% not found',
				p_failed_node, p_ev_seqno;
	end if;

	insert into "_gamersmafia".sl_event
			(ev_origin, ev_seqno, ev_timestamp,
			ev_snapshot, 
			ev_type, ev_data1, ev_data2, ev_data3)
			values 
			(p_failed_node, p_ev_seqfake, CURRENT_TIMESTAMP,
			v_row.ev_snapshot, 
			'FAILOVER_SET', p_failed_node::text, p_backup_node::text,
			p_set_id::text);
	insert into "_gamersmafia".sl_confirm
			(con_origin, con_received, con_seqno, con_timestamp)
			values
			(p_failed_node, "_gamersmafia".getLocalNodeId('_gamersmafia'),
			p_ev_seqfake, CURRENT_TIMESTAMP);
	notify "_gamersmafia_Restart";

	perform "_gamersmafia".failoverSet_int(p_failed_node,
			p_backup_node, p_set_id, p_ev_seqfake);

	return p_ev_seqfake;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION failednode2(integer, integer, integer, bigint, bigint); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION failednode2(integer, integer, integer, bigint, bigint) IS 'FUNCTION failedNode2 (failed_node, backup_node, set_id, ev_seqno, ev_seqfake)

On the node that has the highest sequence number of the failed node,
fake the FAILOVER_SET event.';


--
-- Name: failoverset_int(integer, integer, integer, bigint); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION failoverset_int(integer, integer, integer, bigint) RETURNS integer
    AS $_$
declare
	p_failed_node		alias for $1;
	p_backup_node		alias for $2;
	p_set_id			alias for $3;
	p_wait_seqno		alias for $4;
	v_row				record;
	v_last_sync			int8;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Change the origin of the set now to the backup node.
	-- On the backup node this includes changing all the
	-- trigger and protection stuff
	-- ----
	if p_backup_node = "_gamersmafia".getLocalNodeId('_gamersmafia') then
		delete from "_gamersmafia".sl_setsync
				where ssy_setid = p_set_id;
		delete from "_gamersmafia".sl_subscribe
				where sub_set = p_set_id
					and sub_receiver = p_backup_node;
		update "_gamersmafia".sl_set
				set set_origin = p_backup_node
				where set_id = p_set_id;

		for v_row in select * from "_gamersmafia".sl_table
				where tab_set = p_set_id
				order by tab_id
		loop
			perform "_gamersmafia".alterTableConfigureTriggers(v_row.tab_id);
		end loop;
		insert into "_gamersmafia".sl_event
				(ev_origin, ev_seqno, ev_timestamp,
				ev_snapshot, 
				ev_type, ev_data1, ev_data2, ev_data3, ev_data4)
				values
				(p_backup_node, "pg_catalog".nextval('"_gamersmafia".sl_event_seq'), CURRENT_TIMESTAMP,
				pg_catalog.txid_current_snapshot(),
				'ACCEPT_SET', p_set_id::text,
				p_failed_node::text, p_backup_node::text,
				p_wait_seqno::text);
	else
		delete from "_gamersmafia".sl_subscribe
				where sub_set = p_set_id
					and sub_receiver = p_backup_node;
		update "_gamersmafia".sl_set
				set set_origin = p_backup_node
				where set_id = p_set_id;
	end if;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	-- ----
	-- If we are a subscriber of the set ourself, change our
	-- setsync status to reflect the new set origin.
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id
				and sub_receiver = "_gamersmafia".getLocalNodeId(
						'_gamersmafia'))
	then
		delete from "_gamersmafia".sl_setsync
				where ssy_setid = p_set_id;

		select coalesce(max(ev_seqno), 0) into v_last_sync
				from "_gamersmafia".sl_event
				where ev_origin = p_backup_node
					and ev_type = 'SYNC';
		if v_last_sync > 0 then
			insert into "_gamersmafia".sl_setsync
					(ssy_setid, ssy_origin, ssy_seqno,
					ssy_snapshot, ssy_action_list)
					select p_set_id, p_backup_node, v_last_sync,
					ev_snapshot, NULL
					from "_gamersmafia".sl_event
					where ev_origin = p_backup_node
						and ev_seqno = v_last_sync;
		else
			insert into "_gamersmafia".sl_setsync
					(ssy_setid, ssy_origin, ssy_seqno,
					ssy_snapshot, ssy_action_list)
					values (p_set_id, p_backup_node, '0',
					'0', '0', '0:0:', NULL);
		end if;
				
	end if;

	return p_failed_node;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION failoverset_int(integer, integer, integer, bigint); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION failoverset_int(integer, integer, integer, bigint) IS 'FUNCTION failoverSet_int (failed_node, backup_node, set_id, wait_seqno)

Finish failover for one set.';


--
-- Name: finishtableaftercopy(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION finishtableaftercopy(integer) RETURNS integer
    AS $_$
declare
	p_tab_id		alias for $1;
	v_tab_oid		oid;
	v_tab_fqname	text;
begin
	-- ----
	-- Get the tables OID and fully qualified name
	-- ---
	select	PGC.oid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
		into v_tab_oid, v_tab_fqname
			from "_gamersmafia".sl_table T,   
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
				where T.tab_id = p_tab_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid;
	if not found then
		raise exception 'Table with ID % not found in sl_table', p_tab_id;
	end if;

	-- ----
	-- Reenable indexes and reindex the table.
	-- ----
	update pg_class set relhasindex = 't' where oid = v_tab_oid;
	execute 'reindex table ' || "_gamersmafia".slon_quote_input(v_tab_fqname);

	return 1;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION finishtableaftercopy(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION finishtableaftercopy(integer) IS 'Reenable index maintenance and reindex the table';


--
-- Name: forwardconfirm(integer, integer, bigint, timestamp without time zone); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION forwardconfirm(integer, integer, bigint, timestamp without time zone) RETURNS bigint
    AS $_$
declare
	p_con_origin	alias for $1;
	p_con_received	alias for $2;
	p_con_seqno		alias for $3;
	p_con_timestamp	alias for $4;
	v_max_seqno		bigint;
begin
	select into v_max_seqno coalesce(max(con_seqno), 0)
			from "_gamersmafia".sl_confirm
			where con_origin = p_con_origin
			and con_received = p_con_received;
	if v_max_seqno < p_con_seqno then
		insert into "_gamersmafia".sl_confirm 
				(con_origin, con_received, con_seqno, con_timestamp)
				values (p_con_origin, p_con_received, p_con_seqno,
					p_con_timestamp);
		v_max_seqno = p_con_seqno;
	end if;

	return v_max_seqno;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION forwardconfirm(integer, integer, bigint, timestamp without time zone); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION forwardconfirm(integer, integer, bigint, timestamp without time zone) IS 'forwardConfirm (p_con_origin, p_con_received, p_con_seqno, p_con_timestamp)

Confirms (recorded in sl_confirm) that items from p_con_origin up to
p_con_seqno have been received by node p_con_received as of
p_con_timestamp, and raises an event to forward this confirmation.';


--
-- Name: generate_sync_event(interval); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION generate_sync_event(interval) RETURNS integer
    AS $_$
declare
	p_interval     alias for $1;
	v_node_row     record;

BEGIN
	select 1 into v_node_row from "_gamersmafia".sl_event 
       	  where ev_type = 'SYNC' and ev_origin = "_gamersmafia".getLocalNodeId('_gamersmafia')
          and ev_timestamp > now() - p_interval limit 1;
	if not found then
		-- If there has been no SYNC in the last interval, then push one
		perform "_gamersmafia".createEvent('_gamersmafia', 'SYNC', NULL) 
                                         from "_gamersmafia".sl_node n where no_id = "_gamersmafia".getLocalNodeId('_gamersmafia') 
			and exists (select 1 from "_gamersmafia".sl_set where set_origin = no_id);
		return 1;
	else
		return 0;
	end if;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION generate_sync_event(interval); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION generate_sync_event(interval) IS 'Generate a sync event if there has not been one in the requested interval, and this is a provider node.';


--
-- Name: initializelocalnode(integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION initializelocalnode(integer, text) RETURNS integer
    AS $_$
declare
	p_local_node_id		alias for $1;
	p_comment			alias for $2;
	v_old_node_id		int4;
	v_first_log_no		int4;
	v_event_seq			int8;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Make sure this node is uninitialized or got reset
	-- ----
	select last_value::int4 into v_old_node_id from "_gamersmafia".sl_local_node_id;
	if v_old_node_id != -1 then
		raise exception 'Slony-I: This node is already initialized';
	end if;

	-- ----
	-- Set sl_local_node_id to the requested value and add our
	-- own system to sl_node.
	-- ----
	perform setval('"_gamersmafia".sl_local_node_id', p_local_node_id);
	perform "_gamersmafia".storeNode_int (p_local_node_id, p_comment);

	if (pg_catalog.current_setting('max_identifier_length')::integer - pg_catalog.length('"_gamersmafia"')) < 5 then
		raise notice 'Slony-I: Cluster name length [%] versus system max_identifier_length [%] ', pg_catalog.length('"_gamersmafia"'), pg_catalog.current_setting('max_identifier_length');
		raise notice 'leaves narrow/no room for some Slony-I-generated objects (such as indexes).';
		raise notice 'You may run into problems later!';
	end if;
	
	return p_local_node_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION initializelocalnode(integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION initializelocalnode(integer, text) IS 'no_id - Node ID #
no_comment - Human-oriented comment

Initializes the new node, no_id';


--
-- Name: lockset(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION lockset(integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	v_local_node_id		int4;
	v_set_row			record;
	v_tab_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that the set exists and that we are the origin
	-- and that it is not already locked.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select * into v_set_row from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_set_row.set_origin <> v_local_node_id then
		raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
	end if;
	if v_set_row.set_locked notnull then
		raise exception 'Slony-I: set % is already locked', p_set_id;
	end if;

	-- ----
	-- Place the lockedSet trigger on all tables in the set.
	-- ----
	for v_tab_row in select T.tab_id,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			from "_gamersmafia".sl_table T,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
			where T.tab_set = p_set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
			order by tab_id
	loop
		execute 'create trigger "_gamersmafia_lockedset" ' || 
				'before insert or update or delete on ' ||
				v_tab_row.tab_fqname || ' for each row execute procedure
				"_gamersmafia".lockedSet (''_gamersmafia'');';
	end loop;

	-- ----
	-- Remember our snapshots xmax as for the set locking
	-- ----
	update "_gamersmafia".sl_set
			set set_locked = "pg_catalog".txid_snapshot_xmax("pg_catalog".txid_current_snapshot())
			where set_id = p_set_id;

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION lockset(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION lockset(integer) IS 'lockSet(set_id)

Add a special trigger to all tables of a set that disables access to
it.';


--
-- Name: logswitch_finish(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION logswitch_finish() RETURNS integer
    AS $$
DECLARE
	v_current_status	int4;
	v_dummy				record;
	v_origin	int8;
	v_seqno		int8;
	v_xmin		bigint;
	v_purgeable boolean;
BEGIN
	-- ----
	-- Grab the central configuration lock to prevent race conditions
	-- while changing the sl_log_status sequence value.
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get the current log status.
	-- ----
	select last_value into v_current_status from "_gamersmafia".sl_log_status;

	-- ----
	-- status value 0 or 1 means that there is no log switch in progress
	-- ----
	if v_current_status = 0 or v_current_status = 1 then
		return 0;
	end if;

	-- ----
	-- status = 2: sl_log_1 active, cleanup sl_log_2
	-- ----
	if v_current_status = 2 then
		v_purgeable := 'true';
		-- ----
		-- The cleanup thread calls us after it did the delete and
		-- vacuum of both log tables. If sl_log_2 is empty now, we
		-- can truncate it and the log switch is done.
		-- ----
		
	        for v_origin, v_seqno, v_xmin in
		  select ev_origin, ev_seqno, "pg_catalog".txid_snapshot_xmin(ev_snapshot) from "_gamersmafia".sl_event
	          where (ev_origin, ev_seqno) in (select ev_origin, min(ev_seqno) from "_gamersmafia".sl_event where ev_type = 'SYNC' group by ev_origin)
		loop
			if exists (select 1 from "_gamersmafia".sl_log_2 where log_origin = v_origin and log_txid >= v_xmin limit 1) then
				v_purgeable := 'false';
			end if;
	        end loop;
		if not v_purgeable then
			-- ----
			-- Found a row ... log switch is still in progress.
			-- ----
			raise notice 'Slony-I: log switch to sl_log_1 still in progress - sl_log_2 not truncated';
			return -1;
		end if;

		raise notice 'Slony-I: log switch to sl_log_1 complete - truncate sl_log_2';
		truncate "_gamersmafia".sl_log_2;
		if exists (select * from "pg_catalog".pg_class c, "pg_catalog".pg_namespace n, "pg_catalog".pg_attribute a where c.relname = 'sl_log_2' and n.oid = c.relnamespace and a.attrelid = c.oid and a.attname = 'oid') then
	                execute 'alter table "_gamersmafia".sl_log_2 set without oids;';
		end if;		
		perform "pg_catalog".setval('"_gamersmafia".sl_log_status', 0);
		-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
		perform "_gamersmafia".addPartialLogIndices();

		return 1;
	end if;

	-- ----
	-- status = 3: sl_log_2 active, cleanup sl_log_1
	-- ----
	if v_current_status = 3 then
		v_purgeable := 'true';
		-- ----
		-- The cleanup thread calls us after it did the delete and
		-- vacuum of both log tables. If sl_log_2 is empty now, we
		-- can truncate it and the log switch is done.
		-- ----
	        for v_origin, v_seqno, v_xmin in
		  select ev_origin, ev_seqno, "pg_catalog".txid_snapshot_xmin(ev_snapshot) from "_gamersmafia".sl_event
	          where (ev_origin, ev_seqno) in (select ev_origin, min(ev_seqno) from "_gamersmafia".sl_event where ev_type = 'SYNC' group by ev_origin)
		loop
			if (exists (select 1 from "_gamersmafia".sl_log_1 where log_origin = v_origin and log_txid >= v_xmin limit 1)) then
				v_purgeable := 'false';
			end if;
	        end loop;
		if not v_purgeable then
			-- ----
			-- Found a row ... log switch is still in progress.
			-- ----
			raise notice 'Slony-I: log switch to sl_log_2 still in progress - sl_log_1 not truncated';
			return -1;
		end if;

		raise notice 'Slony-I: log switch to sl_log_2 complete - truncate sl_log_1';
		truncate "_gamersmafia".sl_log_1;
		if exists (select * from "pg_catalog".pg_class c, "pg_catalog".pg_namespace n, "pg_catalog".pg_attribute a where c.relname = 'sl_log_1' and n.oid = c.relnamespace and a.attrelid = c.oid and a.attname = 'oid') then
	                execute 'alter table "_gamersmafia".sl_log_1 set without oids;';
		end if;		
		perform "pg_catalog".setval('"_gamersmafia".sl_log_status', 1);
		-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
		perform "_gamersmafia".addPartialLogIndices();
		return 2;
	end if;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION logswitch_finish(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION logswitch_finish() IS 'logswitch_finish()

Attempt to finalize a log table switch in progress
return values:
  -1 if switch in progress, but not complete
   0 if no switch in progress
   1 if performed truncate on sl_log_2
   2 if performed truncate on sl_log_1
';


--
-- Name: logswitch_start(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION logswitch_start() RETURNS integer
    AS $$
DECLARE
	v_current_status	int4;
BEGIN
	-- ----
	-- Grab the central configuration lock to prevent race conditions
	-- while changing the sl_log_status sequence value.
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get the current log status.
	-- ----
	select last_value into v_current_status from "_gamersmafia".sl_log_status;

	-- ----
	-- status = 0: sl_log_1 active, sl_log_2 clean
	-- Initiate a switch to sl_log_2.
	-- ----
	if v_current_status = 0 then
		perform "pg_catalog".setval('"_gamersmafia".sl_log_status', 3);
		perform "_gamersmafia".registry_set_timestamp(
				'logswitch.laststart', now()::timestamp);
		raise notice 'Slony-I: Logswitch to sl_log_2 initiated';
		return 2;
	end if;

	-- ----
	-- status = 1: sl_log_2 active, sl_log_1 clean
	-- Initiate a switch to sl_log_1.
	-- ----
	if v_current_status = 1 then
		perform "pg_catalog".setval('"_gamersmafia".sl_log_status', 2);
		perform "_gamersmafia".registry_set_timestamp(
				'logswitch.laststart', now()::timestamp);
		raise notice 'Slony-I: Logswitch to sl_log_1 initiated';
		return 1;
	end if;

	raise exception 'Previous logswitch still in progress';
END;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION logswitch_start(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION logswitch_start() IS 'logswitch_start()

Initiate a log table switch if none is in progress';


--
-- Name: mergeset(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION mergeset(integer, integer) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	p_add_id			alias for $2;
	v_origin			int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	-- ----
	-- Check that both sets exist and originate here
	-- ----
	if p_set_id = p_add_id then
		raise exception 'Slony-I: merged set ids cannot be identical';
	end if;
	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
	end if;

	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = p_add_id;
	if not found then
		raise exception 'Slony-I: set % not found', p_add_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				p_add_id;
	end if;

	-- ----
	-- Check that both sets are subscribed by the same set of nodes
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = p_set_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = p_add_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				p_set_id, p_add_id;
	end if;

	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = p_add_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = p_set_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				p_add_id, p_set_id;
	end if;

	-- ----
	-- Check that all ENABLE_SUBSCRIPTION events for the set are confirmed
	-- ----
	if exists (select true from "_gamersmafia".sl_event
			where ev_type = 'ENABLE_SUBSCRIPTION'
			and ev_data1 = p_add_id::text
			and ev_seqno > (select max(con_seqno) from "_gamersmafia".sl_confirm
					where con_origin = ev_origin
					and con_received::text = ev_data3))
	then
		raise exception 'Slony-I: set % has subscriptions in progress - cannot merge',
				p_add_id;
	end if;

	-- ----
	-- Create a SYNC event, merge the sets, create a MERGE_SET event
	-- ----
	perform "_gamersmafia".createEvent('_gamersmafia', 'SYNC', NULL);
	perform "_gamersmafia".mergeSet_int(p_set_id, p_add_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'MERGE_SET', 
			p_set_id::text, p_add_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION mergeset(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION mergeset(integer, integer) IS 'Generate MERGE_SET event to request that sets be merged together.

Both sets must exist, and originate on the same node.  They must be
subscribed by the same set of nodes.';


--
-- Name: mergeset_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION mergeset_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_add_id			alias for $2;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	update "_gamersmafia".sl_sequence
			set seq_set = p_set_id
			where seq_set = p_add_id;
	update "_gamersmafia".sl_table
			set tab_set = p_set_id
			where tab_set = p_add_id;
	delete from "_gamersmafia".sl_subscribe
			where sub_set = p_add_id;
	delete from "_gamersmafia".sl_setsync
			where ssy_setid = p_add_id;
	delete from "_gamersmafia".sl_set
			where set_id = p_add_id;

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION mergeset_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION mergeset_int(integer, integer) IS 'mergeSet_int(set_id, add_id) - Perform MERGE_SET event, merging all objects from 
set add_id into set set_id.';


--
-- Name: moveset(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION moveset(integer, integer) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	p_new_origin		alias for $2;
	v_local_node_id		int4;
	v_set_row			record;
	v_sub_row			record;
	v_sync_seqno		int8;
	v_lv_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that the set is locked and that this locking
	-- happened long enough ago.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select * into v_set_row from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_set_row.set_origin <> v_local_node_id then
		raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
	end if;
	if v_set_row.set_locked isnull then
		raise exception 'Slony-I: set % is not locked', p_set_id;
	end if;
	if v_set_row.set_locked > "pg_catalog".txid_snapshot_xmin("pg_catalog".txid_current_snapshot()) then
		raise exception 'Slony-I: cannot move set % yet, transactions < % are still in progress',
				p_set_id, v_set_row.set_locked;
	end if;

	-- ----
	-- Unlock the set
	-- ----
	perform "_gamersmafia".unlockSet(p_set_id);

	-- ----
	-- Check that the new_origin is an active subscriber of the set
	-- ----
	select * into v_sub_row from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id
			and sub_receiver = p_new_origin;
	if not found then
		raise exception 'Slony-I: set % is not subscribed by node %',
				p_set_id, p_new_origin;
	end if;
	if not v_sub_row.sub_active then
		raise exception 'Slony-I: subsctiption of node % for set % is inactive',
				p_new_origin, p_set_id;
	end if;

	-- ----
	-- Reconfigure everything
	-- ----
	perform "_gamersmafia".moveSet_int(p_set_id, v_local_node_id,
			p_new_origin, 0);

	perform "_gamersmafia".RebuildListenEntries();

	-- ----
	-- At this time we hold access exclusive locks for every table
	-- in the set. But we did move the set to the new origin, so the
	-- createEvent() we are doing now will not record the sequences.
	-- ----
	v_sync_seqno := "_gamersmafia".createEvent('_gamersmafia', 'SYNC');
	insert into "_gamersmafia".sl_seqlog 
			(seql_seqid, seql_origin, seql_ev_seqno, seql_last_value)
			select seq_id, v_local_node_id, v_sync_seqno, seq_last_value
			from "_gamersmafia".sl_seqlastvalue
			where seq_set = p_set_id;
					
	-- ----
	-- Finally we generate the real event
	-- ----
	return "_gamersmafia".createEvent('_gamersmafia', 'MOVE_SET', 
			p_set_id::text, v_local_node_id::text, p_new_origin::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION moveset(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION moveset(integer, integer) IS 'moveSet(set_id, new_origin)

Generate MOVE_SET event to request that the origin for set set_id be moved to node new_origin';


--
-- Name: moveset_int(integer, integer, integer, bigint); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION moveset_int(integer, integer, integer, bigint) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_old_origin		alias for $2;
	p_new_origin		alias for $3;
	p_wait_seqno		alias for $4;
	v_local_node_id		int4;
	v_tab_row			record;
	v_sub_row			record;
	v_sub_node			int4;
	v_sub_last			int4;
	v_sub_next			int4;
	v_last_sync			int8;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get our local node ID
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	-- On the new origin, raise an event - ACCEPT_SET
	if v_local_node_id = p_new_origin then
		-- Create a SYNC event as well so that the ACCEPT_SET has
		-- the same snapshot as the last SYNC generated by the new
		-- origin. This snapshot will be used by other nodes to
		-- finalize the setsync status.
		perform "_gamersmafia".createEvent('_gamersmafia', 'SYNC', NULL);
		perform "_gamersmafia".createEvent('_gamersmafia', 'ACCEPT_SET', 
			p_set_id::text, p_old_origin::text, 
			p_new_origin::text, p_wait_seqno::text);
	end if;

	-- ----
	-- Next we have to reverse the subscription path
	-- ----
	v_sub_last = p_new_origin;
	select sub_provider into v_sub_node
			from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id
			and sub_receiver = p_new_origin;
	if not found then
		raise exception 'Slony-I: subscription path broken in moveSet_int';
	end if;
	while v_sub_node <> p_old_origin loop
		-- ----
		-- Tracing node by node, the old receiver is now in
		-- v_sub_last and the old provider is in v_sub_node.
		-- ----

		-- ----
		-- Get the current provider of this node as next
		-- and change the provider to the previous one in
		-- the reverse chain.
		-- ----
		select sub_provider into v_sub_next
				from "_gamersmafia".sl_subscribe
				where sub_set = p_set_id
					and sub_receiver = v_sub_node
				for update;
		if not found then
			raise exception 'Slony-I: subscription path broken in moveSet_int';
		end if;
		update "_gamersmafia".sl_subscribe
				set sub_provider = v_sub_last
				where sub_set = p_set_id
					and sub_receiver = v_sub_node;

		v_sub_last = v_sub_node;
		v_sub_node = v_sub_next;
	end loop;

	-- ----
	-- This includes creating a subscription for the old origin
	-- ----
	insert into "_gamersmafia".sl_subscribe
			(sub_set, sub_provider, sub_receiver,
			sub_forward, sub_active)
			values (p_set_id, v_sub_last, p_old_origin, true, true);
	if v_local_node_id = p_old_origin then
		select coalesce(max(ev_seqno), 0) into v_last_sync 
				from "_gamersmafia".sl_event
				where ev_origin = p_new_origin
					and ev_type = 'SYNC';
		if v_last_sync > 0 then
			insert into "_gamersmafia".sl_setsync
					(ssy_setid, ssy_origin, ssy_seqno,
					ssy_snapshot, ssy_action_list)
					select p_set_id, p_new_origin, v_last_sync,
					ev_snapshot, NULL
					from "_gamersmafia".sl_event
					where ev_origin = p_new_origin
						and ev_seqno = v_last_sync;
		else
			insert into "_gamersmafia".sl_setsync
					(ssy_setid, ssy_origin, ssy_seqno,
					ssy_snapshot, ssy_action_list)
					values (p_set_id, p_new_origin, '0',
					'0', '0', '0:0:', NULL);
		end if;
	end if;

	-- ----
	-- Now change the ownership of the set.
	-- ----
	update "_gamersmafia".sl_set
			set set_origin = p_new_origin
			where set_id = p_set_id;

	-- ----
	-- On the new origin, delete the obsolete setsync information
	-- and the subscription.
	-- ----
	if v_local_node_id = p_new_origin then
		delete from "_gamersmafia".sl_setsync
				where ssy_setid = p_set_id;
	else
		if v_local_node_id <> p_old_origin then
			--
			-- On every other node, change the setsync so that it will
			-- pick up from the new origins last known sync.
			--
			delete from "_gamersmafia".sl_setsync
					where ssy_setid = p_set_id;
			select coalesce(max(ev_seqno), 0) into v_last_sync
					from "_gamersmafia".sl_event
					where ev_origin = p_new_origin
						and ev_type = 'SYNC';
			if v_last_sync > 0 then
				insert into "_gamersmafia".sl_setsync
						(ssy_setid, ssy_origin, ssy_seqno,
						ssy_snapshot, ssy_action_list)
						select p_set_id, p_new_origin, v_last_sync,
						ev_snapshot, NULL
						from "_gamersmafia".sl_event
						where ev_origin = p_new_origin
							and ev_seqno = v_last_sync;
			else
				insert into "_gamersmafia".sl_setsync
						(ssy_setid, ssy_origin, ssy_seqno,
						ssy_snapshot, ssy_action_list)
						values (p_set_id, p_new_origin, '0',
						'0', '0', '0:0:', NULL);
			end if;
		end if;
	end if;
	delete from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id
			and sub_receiver = p_new_origin;

	-- Regenerate sl_listen since we revised the subscriptions
	perform "_gamersmafia".RebuildListenEntries();

	-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
	perform "_gamersmafia".addPartialLogIndices();

	-- ----
	-- If we are the new or old origin, we have to
	-- adjust the log and deny access trigger configuration.
	-- ----
	if v_local_node_id = p_old_origin or v_local_node_id = p_new_origin then
		for v_tab_row in select tab_id from "_gamersmafia".sl_table
				where tab_set = p_set_id
				order by tab_id
		loop
			perform "_gamersmafia".alterTableConfigureTriggers(v_tab_row.tab_id);
		end loop;
	end if;

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION moveset_int(integer, integer, integer, bigint); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION moveset_int(integer, integer, integer, bigint) IS 'moveSet(set_id, old_origin, new_origin, wait_seqno)

Process MOVE_SET event to request that the origin for set set_id be
moved from old_origin to node new_origin';


--
-- Name: preparetableforcopy(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION preparetableforcopy(integer) RETURNS integer
    AS $_$
declare
	p_tab_id		alias for $1;
	v_tab_oid		oid;
	v_tab_fqname	text;
begin
	-- ----
	-- Get the OID and fully qualified name for the table
	-- ---
	select	PGC.oid,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
		into v_tab_oid, v_tab_fqname
			from "_gamersmafia".sl_table T,   
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
				where T.tab_id = p_tab_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid;
	if not found then
		raise exception 'Table with ID % not found in sl_table', p_tab_id;
	end if;

	-- ----
	-- Try using truncate to empty the table and fallback to
	-- delete on error.
	-- ----
	execute 'truncate ' || "_gamersmafia".slon_quote_input(v_tab_fqname);
	raise notice 'truncate of % succeeded', v_tab_fqname;
	-- ----
	-- Setting pg_class.relhasindex to false will cause copy not to
	-- maintain any indexes. At the end of the copy we will reenable
	-- them and reindex the table. This bulk creating of indexes is
	-- faster.
	-- ----
	update pg_class set relhasindex = 'f' where oid = v_tab_oid;

	return 1;
	exception when others then
		raise notice 'truncate of % failed - doing delete', v_tab_fqname;
		update pg_class set relhasindex = 'f' where oid = v_tab_oid;
		execute 'delete from only ' || "_gamersmafia".slon_quote_input(v_tab_fqname);
		return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION preparetableforcopy(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION preparetableforcopy(integer) IS 'Delete all data and suppress index maintenance';


--
-- Name: rebuildlistenentries(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION rebuildlistenentries() RETURNS integer
    AS $$
declare
	v_row	record;
begin
	-- First remove the entire configuration
	delete from "_gamersmafia".sl_listen;

	-- Second populate the sl_listen configuration with a full
	-- network of all possible paths.
	insert into "_gamersmafia".sl_listen
				(li_origin, li_provider, li_receiver)
			select pa_server, pa_server, pa_client from "_gamersmafia".sl_path;
	while true loop
		insert into "_gamersmafia".sl_listen
					(li_origin, li_provider, li_receiver)
			select distinct li_origin, pa_server, pa_client
				from "_gamersmafia".sl_listen, "_gamersmafia".sl_path
				where li_receiver = pa_server
				  and li_origin <> pa_client
			except
			select li_origin, li_provider, li_receiver
				from "_gamersmafia".sl_listen;

		if not found then
			exit;
		end if;
	end loop;

	-- We now replace specific event-origin,receiver combinations
	-- with a configuration that tries to avoid events arriving at
	-- a node before the data provider actually has the data ready.

	-- Loop over every possible pair of receiver and event origin
	for v_row in select N1.no_id as receiver, N2.no_id as origin
			from "_gamersmafia".sl_node as N1, "_gamersmafia".sl_node as N2
			where N1.no_id <> N2.no_id
	loop
		-- 1st choice:
		-- If we use the event origin as a data provider for any
		-- set that originates on that very node, we are a direct
		-- subscriber to that origin and listen there only.
		if exists (select true from "_gamersmafia".sl_set, "_gamersmafia".sl_subscribe
				where set_origin = v_row.origin
				  and sub_set = set_id
				  and sub_provider = v_row.origin
				  and sub_receiver = v_row.receiver
				  and sub_active)
		then
			delete from "_gamersmafia".sl_listen
				where li_origin = v_row.origin
				  and li_receiver = v_row.receiver;
			insert into "_gamersmafia".sl_listen (li_origin, li_provider, li_receiver)
				values (v_row.origin, v_row.origin, v_row.receiver);
			continue;
		end if;

		-- 2nd choice:
		-- If we are subscribed to any set originating on this
		-- event origin, we want to listen on all data providers
		-- we use for this origin. We are a cascaded subscriber
		-- for sets from this node.
		if exists (select true from "_gamersmafia".sl_set, "_gamersmafia".sl_subscribe
						where set_origin = v_row.origin
						  and sub_set = set_id
						  and sub_receiver = v_row.receiver
						  and sub_active)
		then
			delete from "_gamersmafia".sl_listen
					where li_origin = v_row.origin
					  and li_receiver = v_row.receiver;
			insert into "_gamersmafia".sl_listen (li_origin, li_provider, li_receiver)
					select distinct set_origin, sub_provider, v_row.receiver
						from "_gamersmafia".sl_set, "_gamersmafia".sl_subscribe
						where set_origin = v_row.origin
						  and sub_set = set_id
						  and sub_receiver = v_row.receiver
						  and sub_active;
			continue;
		end if;

	end loop ;

	return null ;
end ;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION rebuildlistenentries(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION rebuildlistenentries() IS 'RebuildListenEntries()

Invoked by various subscription and path modifying functions, this
rewrites the sl_listen entries, adding in all the ones required to
allow communications between nodes in the Slony-I cluster.';


--
-- Name: registernodeconnection(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registernodeconnection(integer) RETURNS integer
    AS $_$
declare
	p_nodeid	alias for $1;
begin
	insert into "_gamersmafia".sl_nodelock
		(nl_nodeid, nl_backendpid)
		values
		(p_nodeid, pg_backend_pid());

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registernodeconnection(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registernodeconnection(integer) IS 'Register (uniquely) the node connection so that only one slon can service the node';


--
-- Name: registry_get_int4(text, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_get_int4(text, integer) RETURNS integer
    AS $_$
DECLARE
	p_key		alias for $1;
	p_default	alias for $2;
	v_value		int4;
BEGIN
	select reg_int4 into v_value from "_gamersmafia".sl_registry
			where reg_key = p_key;
	if not found then 
		v_value = p_default;
		if p_default notnull then
			perform "_gamersmafia".registry_set_int4(p_key, p_default);
		end if;
	else
		if v_value is null then
			raise exception 'Slony-I: registry key % is not an int4 value',
					p_key;
		end if;
	end if;
	return v_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_get_int4(text, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_get_int4(text, integer) IS 'registry_get_int4(key, value)

Get a registry value. If not present, set and return the default.';


--
-- Name: registry_get_text(text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_get_text(text, text) RETURNS text
    AS $_$
DECLARE
	p_key		alias for $1;
	p_default	alias for $2;
	v_value		text;
BEGIN
	select reg_text into v_value from "_gamersmafia".sl_registry
			where reg_key = p_key;
	if not found then 
		v_value = p_default;
		if p_default notnull then
			perform "_gamersmafia".registry_set_text(p_key, p_default);
		end if;
	else
		if v_value is null then
			raise exception 'Slony-I: registry key % is not a text value',
					p_key;
		end if;
	end if;
	return v_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_get_text(text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_get_text(text, text) IS 'registry_get_text(key, value)

Get a registry value. If not present, set and return the default.';


--
-- Name: registry_get_timestamp(text, timestamp without time zone); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_get_timestamp(text, timestamp without time zone) RETURNS timestamp without time zone
    AS $_$
DECLARE
	p_key		alias for $1;
	p_default	alias for $2;
	v_value		timestamp;
BEGIN
	select reg_timestamp into v_value from "_gamersmafia".sl_registry
			where reg_key = p_key;
	if not found then 
		v_value = p_default;
		if p_default notnull then
			perform "_gamersmafia".registry_set_timestamp(p_key, p_default);
		end if;
	else
		if v_value is null then
			raise exception 'Slony-I: registry key % is not an timestamp value',
					p_key;
		end if;
	end if;
	return v_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_get_timestamp(text, timestamp without time zone); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_get_timestamp(text, timestamp without time zone) IS 'registry_get_timestamp(key, value)

Get a registry value. If not present, set and return the default.';


--
-- Name: registry_set_int4(text, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_set_int4(text, integer) RETURNS integer
    AS $_$
DECLARE
	p_key		alias for $1;
	p_value		alias for $2;
BEGIN
	if p_value is null then
		delete from "_gamersmafia".sl_registry
				where reg_key = p_key;
	else
		lock table "_gamersmafia".sl_registry;
		update "_gamersmafia".sl_registry
				set reg_int4 = p_value
				where reg_key = p_key;
		if not found then
			insert into "_gamersmafia".sl_registry (reg_key, reg_int4)
					values (p_key, p_value);
		end if;
	end if;
	return p_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_set_int4(text, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_set_int4(text, integer) IS 'registry_set_int4(key, value)

Set or delete a registry value';


--
-- Name: registry_set_text(text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_set_text(text, text) RETURNS text
    AS $_$
DECLARE
	p_key		alias for $1;
	p_value		alias for $2;
BEGIN
	if p_value is null then
		delete from "_gamersmafia".sl_registry
				where reg_key = p_key;
	else
		lock table "_gamersmafia".sl_registry;
		update "_gamersmafia".sl_registry
				set reg_text = p_value
				where reg_key = p_key;
		if not found then
			insert into "_gamersmafia".sl_registry (reg_key, reg_text)
					values (p_key, p_value);
		end if;
	end if;
	return p_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_set_text(text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_set_text(text, text) IS 'registry_set_text(key, value)

Set or delete a registry value';


--
-- Name: registry_set_timestamp(text, timestamp without time zone); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION registry_set_timestamp(text, timestamp without time zone) RETURNS timestamp without time zone
    AS $_$
DECLARE
	p_key		alias for $1;
	p_value		alias for $2;
BEGIN
	if p_value is null then
		delete from "_gamersmafia".sl_registry
				where reg_key = p_key;
	else
		lock table "_gamersmafia".sl_registry;
		update "_gamersmafia".sl_registry
				set reg_timestamp = p_value
				where reg_key = p_key;
		if not found then
			insert into "_gamersmafia".sl_registry (reg_key, reg_timestamp)
					values (p_key, p_value);
		end if;
	end if;
	return p_value;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION registry_set_timestamp(text, timestamp without time zone); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION registry_set_timestamp(text, timestamp without time zone) IS 'registry_set_timestamp(key, value)

Set or delete a registry value';


--
-- Name: replicate_partition(integer, text, text, text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION replicate_partition(integer, text, text, text, text) RETURNS bigint
    AS $_$
declare
  p_tab_id alias for $1;
  p_nspname alias for $2;
  p_tabname alias for $3;
  p_idxname alias for $4;
  p_comment alias for $5;

  prec record;
  prec2 record;
  v_set_id int4;

begin
-- Look up the parent table; fail if it does not exist
   select c1.oid into prec from pg_catalog.pg_class c1, pg_catalog.pg_class c2, pg_catalog.pg_inherits i, pg_catalog.pg_namespace n where c1.oid = i.inhparent  and c2.oid = i.inhrelid and n.oid = c2.relnamespace and n.nspname = p_nspname and c2.relname = p_tabname;
   if not found then
	raise exception 'replicate_partition: No parent table found for %.%!', p_nspname, p_tabname;
   end if;

-- The parent table tells us what replication set to use
   select tab_set into prec2 from "_gamersmafia".sl_table where tab_reloid = prec.oid;
   if not found then
	raise exception 'replicate_partition: Parent table % for new partition %.% is not replicated!', prec.oid, p_nspname, p_tabname;
   end if;

   v_set_id := prec2.tab_set;

-- Now, we have all the parameters necessary to run add_empty_table_to_replication...
   return "_gamersmafia".add_empty_table_to_replication(v_set_id, p_tab_id, p_nspname, p_tabname, p_idxname, p_comment);
end
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION replicate_partition(integer, text, text, text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION replicate_partition(integer, text, text, text, text) IS 'Add a partition table to replication.
tab_idxname is optional - if NULL, then we use the primary key.
This function looks up replication configuration via the parent table.';


--
-- Name: sequencelastvalue(text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION sequencelastvalue(text) RETURNS bigint
    AS $_$
declare
	p_seqname	alias for $1;
	v_seq_row	record;
begin
	for v_seq_row in execute 'select last_value from ' || "_gamersmafia".slon_quote_input(p_seqname)
	loop
		return v_seq_row.last_value;
	end loop;

	-- not reached
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION sequencelastvalue(text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION sequencelastvalue(text) IS 'sequenceLastValue(p_seqname)

Utility function used in sl_seqlastvalue view to compactly get the
last value from the requested sequence.';


--
-- Name: sequencesetvalue(integer, integer, bigint, bigint); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION sequencesetvalue(integer, integer, bigint, bigint) RETURNS integer
    AS $_$
declare
	p_seq_id			alias for $1;
	p_seq_origin		alias for $2;
	p_ev_seqno			alias for $3;
	p_last_value		alias for $4;
	v_fqname			text;
begin
	-- ----
	-- Get the sequences fully qualified name
	-- ----
	select "_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) into v_fqname
		from "_gamersmafia".sl_sequence SQ,
			"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
		where SQ.seq_id = p_seq_id
			and SQ.seq_reloid = PGC.oid
			and PGC.relnamespace = PGN.oid;
	if not found then
		raise exception 'Slony-I: sequenceSetValue(): sequence % not found', p_seq_id;
	end if;

	-- ----
	-- Update it to the new value
	-- ----
	execute 'select setval(''' || v_fqname ||
			''', ' || p_last_value || ')';

	insert into "_gamersmafia".sl_seqlog
			(seql_seqid, seql_origin, seql_ev_seqno, seql_last_value)
			values (p_seq_id, p_seq_origin, p_ev_seqno, p_last_value);

	return p_seq_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION sequencesetvalue(integer, integer, bigint, bigint); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION sequencesetvalue(integer, integer, bigint, bigint) IS 'sequenceSetValue (seq_id, seq_origin, ev_seqno, last_value)
Set sequence seq_id to have new value last_value.
';


--
-- Name: setaddsequence(integer, integer, text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setaddsequence(integer, integer, text, text) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	p_seq_id			alias for $2;
	p_fqname			alias for $3;
	p_seq_comment		alias for $4;
	v_set_origin		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that we are the origin of the set
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: setAddSequence(): set % not found', p_set_id;
	end if;
	if v_set_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: setAddSequence(): set % has remote origin - submit to origin node', p_set_id;
	end if;

	if exists (select true from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id)
	then
		raise exception 'Slony-I: cannot add sequence to currently subscribed set %',
				p_set_id;
	end if;

	-- ----
	-- Add the sequence to the set and generate the SET_ADD_SEQUENCE event
	-- ----
	perform "_gamersmafia".setAddSequence_int(p_set_id, p_seq_id, p_fqname,
			p_seq_comment);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_ADD_SEQUENCE',
						p_set_id::text, p_seq_id::text, 
						p_fqname::text, p_seq_comment::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setaddsequence(integer, integer, text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setaddsequence(integer, integer, text, text) IS 'setAddSequence (set_id, seq_id, seq_fqname, seq_comment)

On the origin node for set set_id, add sequence seq_fqname to the
replication set, and raise SET_ADD_SEQUENCE to cause this to replicate
to subscriber nodes.';


--
-- Name: setaddsequence_int(integer, integer, text, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setaddsequence_int(integer, integer, text, text) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_seq_id			alias for $2;
	p_fqname			alias for $3;
	p_seq_comment		alias for $4;
	v_local_node_id		int4;
	v_set_origin		int4;
	v_sub_provider		int4;
	v_relkind			char;
	v_seq_reloid		oid;
	v_seq_relname		name;
	v_seq_nspname		name;
	v_sync_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- For sets with a remote origin, check that we are subscribed 
	-- to that set. Otherwise we ignore the sequence because it might 
	-- not even exist in our database.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: setAddSequence_int(): set % not found',
				p_set_id;
	end if;
	if v_set_origin != v_local_node_id then
		select sub_provider into v_sub_provider
				from "_gamersmafia".sl_subscribe
				where sub_set = p_set_id
				and sub_receiver = "_gamersmafia".getLocalNodeId('_gamersmafia');
		if not found then
			return 0;
		end if;
	end if;
	
	-- ----
	-- Get the sequences OID and check that it is a sequence
	-- ----
	select PGC.oid, PGC.relkind, PGC.relname, PGN.nspname 
		into v_seq_reloid, v_relkind, v_seq_relname, v_seq_nspname
			from "pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
			where PGC.relnamespace = PGN.oid
			and "_gamersmafia".slon_quote_input(p_fqname) = "_gamersmafia".slon_quote_brute(PGN.nspname) ||
					'.' || "_gamersmafia".slon_quote_brute(PGC.relname);
	if not found then
		raise exception 'Slony-I: setAddSequence_int(): sequence % not found', 
				p_fqname;
	end if;
	if v_relkind != 'S' then
		raise exception 'Slony-I: setAddSequence_int(): % is not a sequence',
				p_fqname;
	end if;

        select 1 into v_sync_row from "_gamersmafia".sl_sequence where seq_id = p_seq_id;
	if not found then
               v_relkind := 'o';   -- all is OK
        else
                raise exception 'Slony-I: setAddSequence_int(): sequence ID % has already been assigned', p_seq_id;
        end if;

	-- ----
	-- Add the sequence to sl_sequence
	-- ----
	insert into "_gamersmafia".sl_sequence
		(seq_id, seq_reloid, seq_relname, seq_nspname, seq_set, seq_comment) 
		values
		(p_seq_id, v_seq_reloid, v_seq_relname, v_seq_nspname,  p_set_id, p_seq_comment);

	-- ----
	-- On the set origin, fake a sl_seqlog row for the last sync event
	-- ----
	if v_set_origin = v_local_node_id then
		for v_sync_row in select coalesce (max(ev_seqno), 0) as ev_seqno
				from "_gamersmafia".sl_event
				where ev_origin = v_local_node_id
					and ev_type = 'SYNC'
		loop
			insert into "_gamersmafia".sl_seqlog
					(seql_seqid, seql_origin, seql_ev_seqno, 
					seql_last_value) values
					(p_seq_id, v_local_node_id, v_sync_row.ev_seqno,
					"_gamersmafia".sequenceLastValue(p_fqname));
		end loop;
	end if;

	return p_seq_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setaddsequence_int(integer, integer, text, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setaddsequence_int(integer, integer, text, text) IS 'setAddSequence_int (set_id, seq_id, seq_fqname, seq_comment)

This processes the SET_ADD_SEQUENCE event.  On remote nodes that
subscribe to set_id, add the sequence to the replication set.';


--
-- Name: setaddtable(integer, integer, text, name, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setaddtable(integer, integer, text, name, text) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	p_tab_id			alias for $2;
	p_fqname			alias for $3;
	p_tab_idxname		alias for $4;
	p_tab_comment		alias for $5;
	v_set_origin		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that we are the origin of the set
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: setAddTable(): set % not found', p_set_id;
	end if;
	if v_set_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: setAddTable(): set % has remote origin', p_set_id;
	end if;

	if exists (select true from "_gamersmafia".sl_subscribe
			where sub_set = p_set_id)
	then
		raise exception 'Slony-I: cannot add table to currently subscribed set % - must attach to an unsubscribed set',
				p_set_id;
	end if;

	-- ----
	-- Add the table to the set and generate the SET_ADD_TABLE event
	-- ----
	perform "_gamersmafia".setAddTable_int(p_set_id, p_tab_id, p_fqname,
			p_tab_idxname, p_tab_comment);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_ADD_TABLE',
			p_set_id::text, p_tab_id::text, p_fqname::text,
			p_tab_idxname::text, p_tab_comment::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setaddtable(integer, integer, text, name, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setaddtable(integer, integer, text, name, text) IS 'setAddTable (set_id, tab_id, tab_fqname, tab_idxname, tab_comment)

Add table tab_fqname to replication set on origin node, and generate
SET_ADD_TABLE event to allow this to propagate to other nodes.

Note that the table id, tab_id, must be unique ACROSS ALL SETS.';


--
-- Name: setaddtable_int(integer, integer, text, name, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setaddtable_int(integer, integer, text, name, text) RETURNS integer
    AS $_$
declare

	p_set_id		alias for $1;
	p_tab_id		alias for $2;
	p_fqname		alias for $3;
	p_tab_idxname		alias for $4;
	p_tab_comment		alias for $5;
	v_tab_relname		name;
	v_tab_nspname		name;
	v_local_node_id		int4;
	v_set_origin		int4;
	v_sub_provider		int4;
	v_relkind		char;
	v_tab_reloid		oid;
	v_pkcand_nn		boolean;
	v_prec			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- For sets with a remote origin, check that we are subscribed 
	-- to that set. Otherwise we ignore the table because it might 
	-- not even exist in our database.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_set_id;
	if not found then
		raise exception 'Slony-I: setAddTable_int(): set % not found',
				p_set_id;
	end if;
	if v_set_origin != v_local_node_id then
		select sub_provider into v_sub_provider
				from "_gamersmafia".sl_subscribe
				where sub_set = p_set_id
				and sub_receiver = "_gamersmafia".getLocalNodeId('_gamersmafia');
		if not found then
			return 0;
		end if;
	end if;
	
	-- ----
	-- Get the tables OID and check that it is a real table
	-- ----
	select PGC.oid, PGC.relkind, PGC.relname, PGN.nspname into v_tab_reloid, v_relkind, v_tab_relname, v_tab_nspname
			from "pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
			where PGC.relnamespace = PGN.oid
			and "_gamersmafia".slon_quote_input(p_fqname) = "_gamersmafia".slon_quote_brute(PGN.nspname) ||
					'.' || "_gamersmafia".slon_quote_brute(PGC.relname);
	if not found then
		raise exception 'Slony-I: setAddTable_int(): table % not found', 
				p_fqname;
	end if;
	if v_relkind != 'r' then
		raise exception 'Slony-I: setAddTable_int(): % is not a regular table',
				p_fqname;
	end if;

	if not exists (select indexrelid
			from "pg_catalog".pg_index PGX, "pg_catalog".pg_class PGC
			where PGX.indrelid = v_tab_reloid
				and PGX.indexrelid = PGC.oid
				and PGC.relname = p_tab_idxname)
	then
		raise exception 'Slony-I: setAddTable_int(): table % has no index %',
				p_fqname, p_tab_idxname;
	end if;

	-- ----
	-- Verify that the columns in the PK (or candidate) are not NULLABLE
	-- ----

	v_pkcand_nn := 'f';
	for v_prec in select attname from "pg_catalog".pg_attribute where attrelid = 
                        (select oid from "pg_catalog".pg_class where oid = v_tab_reloid) 
                    and attname in (select attname from "pg_catalog".pg_attribute where 
                                    attrelid = (select oid from "pg_catalog".pg_class PGC, 
                                    "pg_catalog".pg_index PGX where 
                                    PGC.relname = p_tab_idxname and PGX.indexrelid=PGC.oid and
                                    PGX.indrelid = v_tab_reloid)) and attnotnull <> 't'
	loop
		raise notice 'Slony-I: setAddTable_int: table % PK column % nullable', p_fqname, v_prec.attname;
		v_pkcand_nn := 't';
	end loop;
	if v_pkcand_nn then
		raise exception 'Slony-I: setAddTable_int: table % not replicable!', p_fqname;
	end if;

	select * into v_prec from "_gamersmafia".sl_table where tab_id = p_tab_id;
	if not found then
		v_pkcand_nn := 't';  -- No-op -- All is well
	else
		raise exception 'Slony-I: setAddTable_int: table id % has already been assigned!', p_tab_id;
	end if;

	-- ----
	-- Add the table to sl_table and create the trigger on it.
	-- ----
	insert into "_gamersmafia".sl_table
			(tab_id, tab_reloid, tab_relname, tab_nspname, 
			tab_set, tab_idxname, tab_altered, tab_comment) 
			values
			(p_tab_id, v_tab_reloid, v_tab_relname, v_tab_nspname,
			p_set_id, p_tab_idxname, false, p_tab_comment);
	perform "_gamersmafia".alterTableAddTriggers(p_tab_id);

	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setaddtable_int(integer, integer, text, name, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setaddtable_int(integer, integer, text, name, text) IS 'setAddTable_int (set_id, tab_id, tab_fqname, tab_idxname, tab_comment)

This function processes the SET_ADD_TABLE event on remote nodes,
adding a table to replication if the remote node is subscribing to its
replication set.';


--
-- Name: setdropsequence(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setdropsequence(integer) RETURNS bigint
    AS $_$
declare
	p_seq_id		alias for $1;
	v_set_id		int4;
	v_set_origin		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Determine set id for this sequence
	-- ----
	select seq_set into v_set_id from "_gamersmafia".sl_sequence where seq_id = p_seq_id;

	-- ----
	-- Ensure sequence exists
	-- ----
	if not found then
		raise exception 'Slony-I: setDropSequence_int(): sequence % not found',
			p_seq_id;
	end if;

	-- ----
	-- Check that we are the origin of the set
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = v_set_id;
	if not found then
		raise exception 'Slony-I: setDropSequence(): set % not found', v_set_id;
	end if;
	if v_set_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: setDropSequence(): set % has origin at another node - submit this to that node', v_set_id;
	end if;

	-- ----
	-- Add the sequence to the set and generate the SET_ADD_SEQUENCE event
	-- ----
	perform "_gamersmafia".setDropSequence_int(p_seq_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_DROP_SEQUENCE',
					p_seq_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setdropsequence(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setdropsequence(integer) IS 'setDropSequence (seq_id)

On the origin node for the set, drop sequence seq_id from replication
set, and raise SET_DROP_SEQUENCE to cause this to replicate to
subscriber nodes.';


--
-- Name: setdropsequence_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setdropsequence_int(integer) RETURNS integer
    AS $_$
declare
	p_seq_id		alias for $1;
	v_set_id		int4;
	v_local_node_id		int4;
	v_set_origin		int4;
	v_sub_provider		int4;
	v_relkind			char;
	v_sync_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Determine set id for this sequence
	-- ----
	select seq_set into v_set_id from "_gamersmafia".sl_sequence where seq_id = p_seq_id;

	-- ----
	-- Ensure sequence exists
	-- ----
	if not found then
		return 0;
	end if;

	-- ----
	-- For sets with a remote origin, check that we are subscribed 
	-- to that set. Otherwise we ignore the sequence because it might 
	-- not even exist in our database.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = v_set_id;
	if not found then
		raise exception 'Slony-I: setDropSequence_int(): set % not found',
				v_set_id;
	end if;
	if v_set_origin != v_local_node_id then
		select sub_provider into v_sub_provider
				from "_gamersmafia".sl_subscribe
				where sub_set = v_set_id
				and sub_receiver = "_gamersmafia".getLocalNodeId('_gamersmafia');
		if not found then
			return 0;
		end if;
	end if;

	-- ----
	-- drop the sequence from sl_sequence, sl_seqlog
	-- ----
	delete from "_gamersmafia".sl_seqlog where seql_seqid = p_seq_id;
	delete from "_gamersmafia".sl_sequence where seq_id = p_seq_id;

	return p_seq_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setdropsequence_int(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setdropsequence_int(integer) IS 'setDropSequence_int (seq_id)

This processes the SET_DROP_SEQUENCE event.  On remote nodes that
subscribe to the set containing sequence seq_id, drop the sequence
from the replication set.';


--
-- Name: setdroptable(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setdroptable(integer) RETURNS bigint
    AS $_$
declare
	p_tab_id		alias for $1;
	v_set_id		int4;
	v_set_origin		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

        -- ----
	-- Determine the set_id
        -- ----
	select tab_set into v_set_id from "_gamersmafia".sl_table where tab_id = p_tab_id;

	-- ----
	-- Ensure table exists
	-- ----
	if not found then
		raise exception 'Slony-I: setDropTable_int(): table % not found',
			p_tab_id;
	end if;

	-- ----
	-- Check that we are the origin of the set
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = v_set_id;
	if not found then
		raise exception 'Slony-I: setDropTable(): set % not found', v_set_id;
	end if;
	if v_set_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: setDropTable(): set % has remote origin', v_set_id;
	end if;

	-- ----
	-- Drop the table from the set and generate the SET_ADD_TABLE event
	-- ----
	perform "_gamersmafia".setDropTable_int(p_tab_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_DROP_TABLE', 
				p_tab_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setdroptable(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setdroptable(integer) IS 'setDropTable (tab_id)

Drop table tab_id from set on origin node, and generate SET_DROP_TABLE
event to allow this to propagate to other nodes.';


--
-- Name: setdroptable_int(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setdroptable_int(integer) RETURNS integer
    AS $_$
declare
	p_tab_id		alias for $1;
	v_set_id		int4;
	v_local_node_id		int4;
	v_set_origin		int4;
	v_sub_provider		int4;
	v_tab_reloid		oid;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

        -- ----
	-- Determine the set_id
        -- ----
	select tab_set into v_set_id from "_gamersmafia".sl_table where tab_id = p_tab_id;

	-- ----
	-- Ensure table exists
	-- ----
	if not found then
		return 0;
	end if;

	-- ----
	-- For sets with a remote origin, check that we are subscribed 
	-- to that set. Otherwise we ignore the table because it might 
	-- not even exist in our database.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = v_set_id;
	if not found then
		raise exception 'Slony-I: setDropTable_int(): set % not found',
				v_set_id;
	end if;
	if v_set_origin != v_local_node_id then
		select sub_provider into v_sub_provider
				from "_gamersmafia".sl_subscribe
				where sub_set = v_set_id
				and sub_receiver = "_gamersmafia".getLocalNodeId('_gamersmafia');
		if not found then
			return 0;
		end if;
	end if;
	
	-- ----
	-- Drop the table from sl_table and drop trigger from it.
	-- ----
	perform "_gamersmafia".alterTableDropTriggers(p_tab_id);
	delete from "_gamersmafia".sl_table where tab_id = p_tab_id;
	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setdroptable_int(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setdroptable_int(integer) IS 'setDropTable_int (tab_id)

This function processes the SET_DROP_TABLE event on remote nodes,
dropping a table from replication if the remote node is subscribing to
its replication set.';


--
-- Name: setmovesequence(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setmovesequence(integer, integer) RETURNS bigint
    AS $_$
declare
	p_seq_id			alias for $1;
	p_new_set_id		alias for $2;
	v_old_set_id		int4;
	v_origin			int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get the sequences current set
	-- ----
	select seq_set into v_old_set_id from "_gamersmafia".sl_sequence
			where seq_id = p_seq_id;
	if not found then
		raise exception 'Slony-I: setMoveSequence(): sequence %d not found', p_seq_id;
	end if;
	
	-- ----
	-- Check that both sets exist and originate here
	-- ----
	if p_new_set_id = v_old_set_id then
		raise exception 'Slony-I: setMoveSequence(): set ids cannot be identical';
	end if;
	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = p_new_set_id;
	if not found then
		raise exception 'Slony-I: setMoveSequence(): set % not found', p_new_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: setMoveSequence(): set % does not originate on local node',
				p_new_set_id;
	end if;

	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = v_old_set_id;
	if not found then
		raise exception 'Slony-I: set % not found', v_old_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				v_old_set_id;
	end if;

	-- ----
	-- Check that both sets are subscribed by the same set of nodes
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = p_new_set_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = v_old_set_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				p_new_set_id, v_old_set_id;
	end if;

	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = v_old_set_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = p_new_set_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				v_old_set_id, p_new_set_id;
	end if;

	-- ----
	-- Change the set the sequence belongs to
	-- ----
	perform "_gamersmafia".setMoveSequence_int(p_seq_id, p_new_set_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_MOVE_SEQUENCE', 
			p_seq_id::text, p_new_set_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setmovesequence(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setmovesequence(integer, integer) IS 'setMoveSequence(p_seq_id, p_new_set_id) - This generates the
SET_MOVE_SEQUENCE event, after validation, notably that both sets
exist, are distinct, and have exactly the same subscription lists';


--
-- Name: setmovesequence_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setmovesequence_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_seq_id			alias for $1;
	p_new_set_id		alias for $2;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	-- ----
	-- Move the sequence to the new set
	-- ----
	update "_gamersmafia".sl_sequence
			set seq_set = p_new_set_id
			where seq_id = p_seq_id;

	return p_seq_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setmovesequence_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setmovesequence_int(integer, integer) IS 'setMoveSequence_int(p_seq_id, p_new_set_id) - processes the
SET_MOVE_SEQUENCE event, moving a sequence to another replication
set.';


--
-- Name: setmovetable(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setmovetable(integer, integer) RETURNS bigint
    AS $_$
declare
	p_tab_id			alias for $1;
	p_new_set_id		alias for $2;
	v_old_set_id		int4;
	v_origin			int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Get the tables current set
	-- ----
	select tab_set into v_old_set_id from "_gamersmafia".sl_table
			where tab_id = p_tab_id;
	if not found then
		raise exception 'Slony-I: table %d not found', p_tab_id;
	end if;
	
	-- ----
	-- Check that both sets exist and originate here
	-- ----
	if p_new_set_id = v_old_set_id then
		raise exception 'Slony-I: set ids cannot be identical';
	end if;
	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = p_new_set_id;
	if not found then
		raise exception 'Slony-I: set % not found', p_new_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				p_new_set_id;
	end if;

	select set_origin into v_origin from "_gamersmafia".sl_set
			where set_id = v_old_set_id;
	if not found then
		raise exception 'Slony-I: set % not found', v_old_set_id;
	end if;
	if v_origin != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: set % does not originate on local node',
				v_old_set_id;
	end if;

	-- ----
	-- Check that both sets are subscribed by the same set of nodes
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = p_new_set_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = v_old_set_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				p_new_set_id, v_old_set_id;
	end if;

	if exists (select true from "_gamersmafia".sl_subscribe SUB1
				where SUB1.sub_set = v_old_set_id
				and SUB1.sub_receiver not in (select SUB2.sub_receiver
						from "_gamersmafia".sl_subscribe SUB2
						where SUB2.sub_set = p_new_set_id))
	then
		raise exception 'Slony-I: subscriber lists of set % and % are different',
				v_old_set_id, p_new_set_id;
	end if;

	-- ----
	-- Change the set the table belongs to
	-- ----
	perform "_gamersmafia".createEvent('_gamersmafia', 'SYNC', NULL);
	perform "_gamersmafia".setMoveTable_int(p_tab_id, p_new_set_id);
	return  "_gamersmafia".createEvent('_gamersmafia', 'SET_MOVE_TABLE', 
			p_tab_id::text, p_new_set_id::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION setmovetable(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION setmovetable(integer, integer) IS 'This processes the SET_MOVE_TABLE event.  The table is moved 
to the destination set.';


--
-- Name: setmovetable_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION setmovetable_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_tab_id			alias for $1;
	p_new_set_id		alias for $2;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;
	
	-- ----
	-- Move the table to the new set
	-- ----
	update "_gamersmafia".sl_table
			set tab_set = p_new_set_id
			where tab_id = p_tab_id;

	return p_tab_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: shouldslonyvacuumtable(name, name); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION shouldslonyvacuumtable(name, name) RETURNS boolean
    AS $_$
declare
	i_nspname alias for $1;
	i_tblname alias for $2;
	c_table oid;
	c_namespace oid;
	c_enabled boolean;
	v_dummy int4;
begin
	select 1 into v_dummy from "pg_catalog".pg_settings where name = 'autovacuum' and setting = 'on';
	if not found then
		return 't'::boolean;       -- If autovac is turned off, then we gotta vacuum
	end if;
	
	select into c_namespace oid from "pg_catalog".pg_namespace where nspname = i_nspname;
	if not found then
		raise exception 'Slony-I: namespace % does not exist', i_nspname;
	end if;
	select into c_table oid from "pg_catalog".pg_class where relname = i_tblname and relnamespace = c_namespace;
	if not found then
		raise warning 'Slony-I: table % does not exist in namespace %/%', tblname, c_namespace, i_nspname;
		return 'f'::boolean;
	end if;
	
	-- So, the table is legit; try to look it up for autovacuum policy
	select enabled into c_enabled from "pg_catalog".pg_autovacuum where vacrelid = c_table;

	if not found then
		return 'f'::boolean;   -- Autovac is turned on, and this table has no overriding handling
	end if;

	if c_enabled then
		return 'f'::boolean;   -- Autovac is expressly turned on for this table
	end if;

	return 't'::boolean;
end;$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION shouldslonyvacuumtable(name, name); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION shouldslonyvacuumtable(name, name) IS 'returns false if autovacuum handles vacuuming of the table, or if the table does not exist; returns true if Slony-I should manage it';


--
-- Name: slon_quote_brute(text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slon_quote_brute(text) RETURNS text
    AS $_$
declare	
    p_tab_fqname alias for $1;
    v_fqname text default '';
begin
    v_fqname := '"' || replace(p_tab_fqname,'"','""') || '"';
    return v_fqname;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slon_quote_brute(text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slon_quote_brute(text) IS 'Brutally quote the given text';


--
-- Name: slon_quote_input(text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slon_quote_input(text) RETURNS text
    AS $_$
  declare
     p_tab_fqname alias for $1;
     v_nsp_name text;
     v_tab_name text;
	 v_i integer;
	 v_l integer;
     v_pq2 integer;
begin
	v_l := length(p_tab_fqname);

	-- Let us search for the dot
	if p_tab_fqname like '"%' then
		-- if the first part of the ident starts with a double quote, search
		-- for the closing double quote, skipping over double double quotes.
		v_i := 2;
		while v_i <= v_l loop
			if substr(p_tab_fqname, v_i, 1) != '"' then
				v_i := v_i + 1;
			else
				v_i := v_i + 1;
				if substr(p_tab_fqname, v_i, 1) != '"' then
					exit;
				end if;
				v_i := v_i + 1;
			end if;
		end loop;
	else
		-- first part of ident is not quoted, search for the dot directly
		v_i := 1;
		while v_i <= v_l loop
			if substr(p_tab_fqname, v_i, 1) = '.' then
				exit;
			end if;
			v_i := v_i + 1;
		end loop;
	end if;

	-- v_i now points at the dot or behind the string.

	if substr(p_tab_fqname, v_i, 1) = '.' then
		-- There is a dot now, so split the ident into its namespace
		-- and objname parts and make sure each is quoted
		v_nsp_name := substr(p_tab_fqname, 1, v_i - 1);
		v_tab_name := substr(p_tab_fqname, v_i + 1);
		if v_nsp_name not like '"%' then
			v_nsp_name := '"' || replace(v_nsp_name, '"', '""') ||
						  '"';
		end if;
		if v_tab_name not like '"%' then
			v_tab_name := '"' || replace(v_tab_name, '"', '""') ||
						  '"';
		end if;

		return v_nsp_name || '.' || v_tab_name;
	else
		-- No dot ... must be just an ident without schema
		if p_tab_fqname like '"%' then
			return p_tab_fqname;
		else
			return '"' || replace(p_tab_fqname, '"', '""') || '"';
		end if;
	end if;

end;$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slon_quote_input(text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slon_quote_input(text) IS 'quote all words that aren''t quoted yet';


--
-- Name: slonyversion(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slonyversion() RETURNS text
    AS $$
begin
	return "_gamersmafia".slonyVersionMajor() || '.' || 
	       "_gamersmafia".slonyVersionMinor() || '.' || 
	       "_gamersmafia".slonyVersionPatchlevel();
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slonyversion(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slonyversion() IS 'Returns the version number of the slony schema';


--
-- Name: slonyversionmajor(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slonyversionmajor() RETURNS integer
    AS $$
begin
	return 2;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slonyversionmajor(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slonyversionmajor() IS 'Returns the major version number of the slony schema';


--
-- Name: slonyversionminor(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slonyversionminor() RETURNS integer
    AS $$
begin
	return 0;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slonyversionminor(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slonyversionminor() IS 'Returns the minor version number of the slony schema';


--
-- Name: slonyversionpatchlevel(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION slonyversionpatchlevel() RETURNS integer
    AS $$
begin
	return 2;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION slonyversionpatchlevel(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION slonyversionpatchlevel() IS 'Returns the version patch level of the slony schema';


--
-- Name: storelisten(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storelisten(integer, integer, integer) RETURNS bigint
    AS $_$
declare
	p_origin		alias for $1;
	p_provider	alias for $2;
	p_receiver	alias for $3;
begin
	perform "_gamersmafia".storeListen_int (p_origin, p_provider, p_receiver);
	return  "_gamersmafia".createEvent ('_gamersmafia', 'STORE_LISTEN',
			p_origin::text, p_provider::text, p_receiver::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storelisten(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storelisten(integer, integer, integer) IS 'FUNCTION storeListen (li_origin, li_provider, li_receiver)

generate STORE_LISTEN event, indicating that receiver node li_receiver
listens to node li_provider in order to get messages coming from node
li_origin.';


--
-- Name: storelisten_int(integer, integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storelisten_int(integer, integer, integer) RETURNS integer
    AS $_$
declare
	p_li_origin		alias for $1;
	p_li_provider	alias for $2;
	p_li_receiver	alias for $3;
	v_exists		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	select 1 into v_exists
			from "_gamersmafia".sl_listen
			where li_origin = p_li_origin
			and li_provider = p_li_provider
			and li_receiver = p_li_receiver;
	if not found then
		-- ----
		-- In case we receive STORE_LISTEN events before we know
		-- about the nodes involved in this, we generate those nodes
		-- as pending.
		-- ----
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_li_origin) then
			perform "_gamersmafia".storeNode_int (p_li_origin, '<event pending>');
		end if;
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_li_provider) then
			perform "_gamersmafia".storeNode_int (p_li_provider, '<event pending>');
		end if;
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_li_receiver) then
			perform "_gamersmafia".storeNode_int (p_li_receiver, '<event pending>');
		end if;

		insert into "_gamersmafia".sl_listen
				(li_origin, li_provider, li_receiver) values
				(p_li_origin, p_li_provider, p_li_receiver);
	end if;

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storelisten_int(integer, integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storelisten_int(integer, integer, integer) IS 'FUNCTION storeListen_int (li_origin, li_provider, li_receiver)

Process STORE_LISTEN event, indicating that receiver node li_receiver
listens to node li_provider in order to get messages coming from node
li_origin.';


--
-- Name: storenode(integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storenode(integer, text) RETURNS bigint
    AS $_$
declare
	p_no_id			alias for $1;
	p_no_comment	alias for $2;
begin
	perform "_gamersmafia".storeNode_int (p_no_id, p_no_comment);
	return  "_gamersmafia".createEvent('_gamersmafia', 'STORE_NODE',
									p_no_id::text, p_no_comment::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storenode(integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storenode(integer, text) IS 'no_id - Node ID #
no_comment - Human-oriented comment

Generate the STORE_NODE event for node no_id';


--
-- Name: storenode_int(integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storenode_int(integer, text) RETURNS integer
    AS $_$
declare
	p_no_id			alias for $1;
	p_no_comment	alias for $2;
	v_old_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check if the node exists
	-- ----
	select * into v_old_row
			from "_gamersmafia".sl_node
			where no_id = p_no_id
			for update;
	if found then 
		-- ----
		-- Node exists, update the existing row.
		-- ----
		update "_gamersmafia".sl_node
				set no_comment = p_no_comment
				where no_id = p_no_id;
	else
		-- ----
		-- New node, insert the sl_node row
		-- ----
		insert into "_gamersmafia".sl_node
				(no_id, no_active, no_comment) values
				(p_no_id, 'f', p_no_comment);
	end if;

	return p_no_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storenode_int(integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storenode_int(integer, text) IS 'no_id - Node ID #
no_comment - Human-oriented comment

Internal function to process the STORE_NODE event for node no_id';


--
-- Name: storepath(integer, integer, text, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storepath(integer, integer, text, integer) RETURNS bigint
    AS $_$
declare
	p_pa_server		alias for $1;
	p_pa_client		alias for $2;
	p_pa_conninfo	alias for $3;
	p_pa_connretry	alias for $4;
begin
	perform "_gamersmafia".storePath_int(p_pa_server, p_pa_client,
			p_pa_conninfo, p_pa_connretry);
	return  "_gamersmafia".createEvent('_gamersmafia', 'STORE_PATH', 
			p_pa_server::text, p_pa_client::text, 
			p_pa_conninfo::text, p_pa_connretry::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storepath(integer, integer, text, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storepath(integer, integer, text, integer) IS 'FUNCTION storePath (pa_server, pa_client, pa_conninfo, pa_connretry)

Generate the STORE_PATH event indicating that node pa_client can
access node pa_server using DSN pa_conninfo';


--
-- Name: storepath_int(integer, integer, text, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storepath_int(integer, integer, text, integer) RETURNS integer
    AS $_$
declare
	p_pa_server		alias for $1;
	p_pa_client		alias for $2;
	p_pa_conninfo	alias for $3;
	p_pa_connretry	alias for $4;
	v_dummy			int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check if the path already exists
	-- ----
	select 1 into v_dummy
			from "_gamersmafia".sl_path
			where pa_server = p_pa_server
			and pa_client = p_pa_client
			for update;
	if found then
		-- ----
		-- Path exists, update pa_conninfo
		-- ----
		update "_gamersmafia".sl_path
				set pa_conninfo = p_pa_conninfo,
					pa_connretry = p_pa_connretry
				where pa_server = p_pa_server
				and pa_client = p_pa_client;
	else
		-- ----
		-- New path
		--
		-- In case we receive STORE_PATH events before we know
		-- about the nodes involved in this, we generate those nodes
		-- as pending.
		-- ----
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_pa_server) then
			perform "_gamersmafia".storeNode_int (p_pa_server, '<event pending>');
		end if;
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_pa_client) then
			perform "_gamersmafia".storeNode_int (p_pa_client, '<event pending>');
		end if;
		insert into "_gamersmafia".sl_path
				(pa_server, pa_client, pa_conninfo, pa_connretry) values
				(p_pa_server, p_pa_client, p_pa_conninfo, p_pa_connretry);
	end if;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storepath_int(integer, integer, text, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storepath_int(integer, integer, text, integer) IS 'FUNCTION storePath (pa_server, pa_client, pa_conninfo, pa_connretry)

Process the STORE_PATH event indicating that node pa_client can
access node pa_server using DSN pa_conninfo';


--
-- Name: storeset(integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storeset(integer, text) RETURNS bigint
    AS $_$
declare
	p_set_id			alias for $1;
	p_set_comment		alias for $2;
	v_local_node_id		int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');

	insert into "_gamersmafia".sl_set
			(set_id, set_origin, set_comment) values
			(p_set_id, v_local_node_id, p_set_comment);

	return "_gamersmafia".createEvent('_gamersmafia', 'STORE_SET', 
			p_set_id::text, v_local_node_id::text, p_set_comment::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storeset(integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storeset(integer, text) IS 'Generate STORE_SET event for set set_id with human readable comment set_comment';


--
-- Name: storeset_int(integer, integer, text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION storeset_int(integer, integer, text) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	p_set_origin		alias for $2;
	p_set_comment		alias for $3;
	v_dummy				int4;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	select 1 into v_dummy
			from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if found then 
		update "_gamersmafia".sl_set
				set set_comment = p_set_comment
				where set_id = p_set_id;
	else
		if not exists (select 1 from "_gamersmafia".sl_node
						where no_id = p_set_origin) then
			perform "_gamersmafia".storeNode_int (p_set_origin, '<event pending>');
		end if;
		insert into "_gamersmafia".sl_set
				(set_id, set_origin, set_comment) values
				(p_set_id, p_set_origin, p_set_comment);
	end if;

	-- Run addPartialLogIndices() to try to add indices to unused sl_log_? table
	perform "_gamersmafia".addPartialLogIndices();

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION storeset_int(integer, integer, text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION storeset_int(integer, integer, text) IS 'storeSet_int (set_id, set_origin, set_comment)

Process the STORE_SET event, indicating the new set with given ID,
origin node, and human readable comment.';


--
-- Name: subscribeset(integer, integer, integer, boolean); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION subscribeset(integer, integer, integer, boolean) RETURNS bigint
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_provider		alias for $2;
	p_sub_receiver		alias for $3;
	p_sub_forward		alias for $4;
	v_set_origin		int4;
	v_ev_seqno			int8;
	v_rec			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that this is called on the provider node
	-- ----
	if p_sub_provider != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: subscribeSet() must be called on provider';
	end if;

	-- ----
	-- Check that the origin and provider of the set are remote
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_sub_set;
	if not found then
		raise exception 'Slony-I: subscribeSet(): set % not found', p_sub_set;
	end if;
	if v_set_origin = p_sub_receiver then
		raise exception 
				'Slony-I: subscribeSet(): set origin and receiver cannot be identical';
	end if;
	if p_sub_receiver = p_sub_provider then
		raise exception 
				'Slony-I: subscribeSet(): set provider and receiver cannot be identical';
	end if;

	-- ---
	-- Verify that the provider is either the origin or an active subscriber
	-- Bug report #1362
	-- ---
	if v_set_origin <> p_sub_provider then
		if not exists (select 1 from "_gamersmafia".sl_subscribe
			where sub_set = p_sub_set and 
                              sub_receiver = p_sub_provider and
			      sub_forward and sub_active) then
			raise exception 'Slony-I: subscribeSet(): provider % is not an active forwarding node for replication set %', p_sub_provider, p_sub_set;
		end if;
	end if;

	-- ----
	-- Create the SUBSCRIBE_SET event
	-- ----
	v_ev_seqno :=  "_gamersmafia".createEvent('_gamersmafia', 'SUBSCRIBE_SET', 
			p_sub_set::text, p_sub_provider::text, p_sub_receiver::text, 
			case p_sub_forward when true then 't' else 'f' end);

	-- ----
	-- Call the internal procedure to store the subscription
	-- ----
	perform "_gamersmafia".subscribeSet_int(p_sub_set, p_sub_provider,
			p_sub_receiver, p_sub_forward);

	return v_ev_seqno;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION subscribeset(integer, integer, integer, boolean); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION subscribeset(integer, integer, integer, boolean) IS 'subscribeSet (sub_set, sub_provider, sub_receiver, sub_forward)

Makes sure that the receiver is not the provider, then stores the
subscription, and publishes the SUBSCRIBE_SET event to other nodes.';


--
-- Name: subscribeset_int(integer, integer, integer, boolean); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION subscribeset_int(integer, integer, integer, boolean) RETURNS integer
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_provider		alias for $2;
	p_sub_receiver		alias for $3;
	p_sub_forward		alias for $4;
	v_set_origin		int4;
	v_sub_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Provider change is only allowed for active sets
	-- ----
	if p_sub_receiver = "_gamersmafia".getLocalNodeId('_gamersmafia') then
		select sub_active into v_sub_row from "_gamersmafia".sl_subscribe
				where sub_set = p_sub_set
				and sub_receiver = p_sub_receiver;
		if found then
			if not v_sub_row.sub_active then
				raise exception 'Slony-I: subscribeSet_int(): set % is not active, cannot change provider',
						p_sub_set;
			end if;
		end if;
	end if;

	-- ----
	-- Try to change provider and/or forward for an existing subscription
	-- ----
	update "_gamersmafia".sl_subscribe
			set sub_provider = p_sub_provider,
				sub_forward = p_sub_forward
			where sub_set = p_sub_set
			and sub_receiver = p_sub_receiver;
	if found then
		-- ----
		-- Rewrite sl_listen table
		-- ----
		perform "_gamersmafia".RebuildListenEntries();

		return p_sub_set;
	end if;

	-- ----
	-- Not found, insert a new one
	-- ----
	if not exists (select true from "_gamersmafia".sl_path
			where pa_server = p_sub_provider
			and pa_client = p_sub_receiver)
	then
		insert into "_gamersmafia".sl_path
				(pa_server, pa_client, pa_conninfo, pa_connretry)
				values 
				(p_sub_provider, p_sub_receiver, 
				'<event pending>', 10);
	end if;
	insert into "_gamersmafia".sl_subscribe
			(sub_set, sub_provider, sub_receiver, sub_forward, sub_active)
			values (p_sub_set, p_sub_provider, p_sub_receiver,
				p_sub_forward, false);

	-- ----
	-- If the set origin is here, then enable the subscription
	-- ----
	select set_origin into v_set_origin
			from "_gamersmafia".sl_set
			where set_id = p_sub_set;
	if not found then
		raise exception 'Slony-I: subscribeSet_int(): set % not found', p_sub_set;
	end if;

	if v_set_origin = "_gamersmafia".getLocalNodeId('_gamersmafia') then
		perform "_gamersmafia".createEvent('_gamersmafia', 'ENABLE_SUBSCRIPTION', 
				p_sub_set::text, p_sub_provider::text, p_sub_receiver::text, 
				case p_sub_forward when true then 't' else 'f' end);
		perform "_gamersmafia".enableSubscription(p_sub_set, 
				p_sub_provider, p_sub_receiver);
	end if;

	-- ----
	-- Rewrite sl_listen table
	-- ----
	perform "_gamersmafia".RebuildListenEntries();

	return p_sub_set;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION subscribeset_int(integer, integer, integer, boolean); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION subscribeset_int(integer, integer, integer, boolean) IS 'subscribeSet_int (sub_set, sub_provider, sub_receiver, sub_forward)

Internal actions for subscribing receiver sub_receiver to subscription
set sub_set.';


--
-- Name: tablestovacuum(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION tablestovacuum() RETURNS SETOF vactables
    AS $$
declare
	prec "_gamersmafia".vactables%rowtype;
begin
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_event';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_confirm';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_setsync';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_log_1';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_log_2';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_seqlog';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := '_gamersmafia';
	prec.relname := 'sl_archive_counter';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := 'pg_catalog';
	prec.relname := 'pg_listener';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;
	prec.nspname := 'pg_catalog';
	prec.relname := 'pg_statistic';
	if "_gamersmafia".ShouldSlonyVacuumTable(prec.nspname, prec.relname) then
		return next prec;
	end if;

   return;
end
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION tablestovacuum(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION tablestovacuum() IS 'Return a list of tables that require frequent vacuuming.  The
function is used so that the list is not hardcoded into C code.';


--
-- Name: terminatenodeconnections(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION terminatenodeconnections(integer) RETURNS integer
    AS $_$
declare
	p_failed_node	alias for $1;
	v_row			record;
begin
	for v_row in select nl_nodeid, nl_conncnt,
			nl_backendpid from "_gamersmafia".sl_nodelock
			where nl_nodeid = p_failed_node for update
	loop
		perform "_gamersmafia".killBackend(v_row.nl_backendpid, 'TERM');
		delete from "_gamersmafia".sl_nodelock
			where nl_nodeid = v_row.nl_nodeid
			and nl_conncnt = v_row.nl_conncnt;
	end loop;

	return 0;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION terminatenodeconnections(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION terminatenodeconnections(integer) IS 'terminates all backends that have registered to be from the given node';


--
-- Name: uninstallnode(); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION uninstallnode() RETURNS integer
    AS $$
declare
	v_tab_row		record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	raise notice 'Slony-I: Please drop schema "_gamersmafia"';
	return 0;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION uninstallnode(); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION uninstallnode() IS 'Reset the whole database to standalone by removing the whole
replication system.';


--
-- Name: unlockset(integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION unlockset(integer) RETURNS integer
    AS $_$
declare
	p_set_id			alias for $1;
	v_local_node_id		int4;
	v_set_row			record;
	v_tab_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that the set exists and that we are the origin
	-- and that it is not already locked.
	-- ----
	v_local_node_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
	select * into v_set_row from "_gamersmafia".sl_set
			where set_id = p_set_id
			for update;
	if not found then
		raise exception 'Slony-I: set % not found', p_set_id;
	end if;
	if v_set_row.set_origin <> v_local_node_id then
		raise exception 'Slony-I: set % does not originate on local node',
				p_set_id;
	end if;
	if v_set_row.set_locked isnull then
		raise exception 'Slony-I: set % is not locked', p_set_id;
	end if;

	-- ----
	-- Drop the lockedSet trigger from all tables in the set.
	-- ----
	for v_tab_row in select T.tab_id,
			"_gamersmafia".slon_quote_brute(PGN.nspname) || '.' ||
			"_gamersmafia".slon_quote_brute(PGC.relname) as tab_fqname
			from "_gamersmafia".sl_table T,
				"pg_catalog".pg_class PGC, "pg_catalog".pg_namespace PGN
			where T.tab_set = p_set_id
				and T.tab_reloid = PGC.oid
				and PGC.relnamespace = PGN.oid
			order by tab_id
	loop
		execute 'drop trigger "_gamersmafia_lockedset" ' || 
				'on ' || v_tab_row.tab_fqname;
	end loop;

	-- ----
	-- Clear out the set_locked field
	-- ----
	update "_gamersmafia".sl_set
			set set_locked = NULL
			where set_id = p_set_id;

	return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION unlockset(integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION unlockset(integer) IS 'Remove the special trigger from all tables of a set that disables access to it.';


--
-- Name: unsubscribeset(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION unsubscribeset(integer, integer) RETURNS bigint
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_receiver		alias for $2;
	v_tab_row			record;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- Check that this is called on the receiver node
	-- ----
	if p_sub_receiver != "_gamersmafia".getLocalNodeId('_gamersmafia') then
		raise exception 'Slony-I: unsubscribeSet() must be called on receiver';
	end if;

	-- ----
	-- Check that this does not break any chains
	-- ----
	if exists (select true from "_gamersmafia".sl_subscribe
			where sub_set = p_sub_set
				and sub_provider = p_sub_receiver)
	then
		raise exception 'Slony-I: Cannot unsubscribe set % while being provider',
				p_sub_set;
	end if;

	-- ----
	-- Remove the replication triggers.
	-- ----
	for v_tab_row in select tab_id from "_gamersmafia".sl_table
			where tab_set = p_sub_set
			order by tab_id
	loop
		perform "_gamersmafia".alterTableDropTriggers(v_tab_row.tab_id);
	end loop;

	-- ----
	-- Remove the setsync status. This will also cause the
	-- worker thread to ignore the set and stop replicating
	-- right now.
	-- ----
	delete from "_gamersmafia".sl_setsync
			where ssy_setid = p_sub_set;

	-- ----
	-- Remove all sl_table and sl_sequence entries for this set.
	-- Should we ever subscribe again, the initial data
	-- copy process will create new ones.
	-- ----
	delete from "_gamersmafia".sl_table
			where tab_set = p_sub_set;
	delete from "_gamersmafia".sl_sequence
			where seq_set = p_sub_set;

	-- ----
	-- Call the internal procedure to drop the subscription
	-- ----
	perform "_gamersmafia".unsubscribeSet_int(p_sub_set, p_sub_receiver);

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	-- ----
	-- Create the UNSUBSCRIBE_SET event
	-- ----
	return  "_gamersmafia".createEvent('_gamersmafia', 'UNSUBSCRIBE_SET', 
			p_sub_set::text, p_sub_receiver::text);
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION unsubscribeset(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION unsubscribeset(integer, integer) IS 'unsubscribeSet (sub_set, sub_receiver) 

Unsubscribe node sub_receiver from subscription set sub_set.  This is
invoked on the receiver node.  It verifies that this does not break
any chains (e.g. - where sub_receiver is a provider for another node),
then restores tables, drops Slony-specific keys, drops table entries
for the set, drops the subscription, and generates an UNSUBSCRIBE_SET
node to publish that the node is being dropped.';


--
-- Name: unsubscribeset_int(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION unsubscribeset_int(integer, integer) RETURNS integer
    AS $_$
declare
	p_sub_set			alias for $1;
	p_sub_receiver		alias for $2;
begin
	-- ----
	-- Grab the central configuration lock
	-- ----
	lock table "_gamersmafia".sl_config_lock;

	-- ----
	-- All the real work is done before event generation on the
	-- subscriber.
	-- ----
	delete from "_gamersmafia".sl_subscribe
			where sub_set = p_sub_set
				and sub_receiver = p_sub_receiver;

	-- Rewrite sl_listen table
	perform "_gamersmafia".RebuildListenEntries();

	return p_sub_set;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION unsubscribeset_int(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION unsubscribeset_int(integer, integer) IS 'unsubscribeSet_int (sub_set, sub_receiver)

All the REAL work of removing the subscriber is done before the event
is generated, so this function just has to drop the references to the
subscription in sl_subscribe.';


--
-- Name: updaterelname(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION updaterelname(integer, integer) RETURNS integer
    AS $_$
declare
        p_set_id                alias for $1;
        p_only_on_node          alias for $2;
        v_no_id                 int4;
        v_set_origin            int4;
begin
        -- ----
        -- Grab the central configuration lock
        -- ----
        lock table "_gamersmafia".sl_config_lock;

        -- ----
        -- Check that we either are the set origin or a current
        -- subscriber of the set.
        -- ----
        v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
        select set_origin into v_set_origin
                        from "_gamersmafia".sl_set
                        where set_id = p_set_id
                        for update;
        if not found then
                raise exception 'Slony-I: set % not found', p_set_id;
        end if;
        if v_set_origin <> v_no_id
                and not exists (select 1 from "_gamersmafia".sl_subscribe
                        where sub_set = p_set_id
                        and sub_receiver = v_no_id)
        then
                return 0;
        end if;
    
        -- ----
        -- If execution on only one node is requested, check that
        -- we are that node.
        -- ----
        if p_only_on_node > 0 and p_only_on_node <> v_no_id then
                return 0;
        end if;
        update "_gamersmafia".sl_table set 
                tab_relname = PGC.relname, tab_nspname = PGN.nspname
                from pg_catalog.pg_class PGC, pg_catalog.pg_namespace PGN 
                where "_gamersmafia".sl_table.tab_reloid = PGC.oid
                        and PGC.relnamespace = PGN.oid;
        update "_gamersmafia".sl_sequence set
                seq_relname = PGC.relname, seq_nspname = PGN.nspname
                from pg_catalog.pg_class PGC, pg_catalog.pg_namespace PGN
                where "_gamersmafia".sl_sequence.seq_reloid = PGC.oid
                and PGC.relnamespace = PGN.oid;
        return p_set_id;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION updaterelname(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION updaterelname(integer, integer) IS 'updateRelname(set_id, only_on_node)';


--
-- Name: updatereloid(integer, integer); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION updatereloid(integer, integer) RETURNS integer
    AS $_$
declare
        p_set_id                alias for $1;
        p_only_on_node          alias for $2;
        v_no_id                 int4;
        v_set_origin            int4;
	prec			record;
begin
        -- ----
        -- Grab the central configuration lock
        -- ----
        lock table "_gamersmafia".sl_config_lock;

        -- ----
        -- Check that we either are the set origin or a current
        -- subscriber of the set.
        -- ----
        v_no_id := "_gamersmafia".getLocalNodeId('_gamersmafia');
        select set_origin into v_set_origin
                        from "_gamersmafia".sl_set
                        where set_id = p_set_id
                        for update;
        if not found then
                raise exception 'Slony-I: set % not found', p_set_id;
        end if;
        if v_set_origin <> v_no_id
                and not exists (select 1 from "_gamersmafia".sl_subscribe
                        where sub_set = p_set_id
                        and sub_receiver = v_no_id)
        then
                return 0;
        end if;

        -- ----
        -- If execution on only one node is requested, check that
        -- we are that node.
        -- ----
        if p_only_on_node > 0 and p_only_on_node <> v_no_id then
                return 0;
        end if;

	-- Update OIDs for tables to values pulled from non-table objects in pg_class
	-- This ensures that we won't have collisions when repairing the oids
	for prec in select tab_id from "_gamersmafia".sl_table loop
		update "_gamersmafia".sl_table set tab_reloid = (select oid from pg_class pc where relkind <> 'r' and not exists (select 1 from "_gamersmafia".sl_table t2 where t2.tab_reloid = pc.oid) limit 1)
		where tab_id = prec.tab_id;
	end loop;

        update "_gamersmafia".sl_table set
                tab_reloid = PGC.oid
                from pg_catalog.pg_class PGC, pg_catalog.pg_namespace PGN
                where "_gamersmafia".slon_quote_brute("_gamersmafia".sl_table.tab_relname) = "_gamersmafia".slon_quote_brute(PGC.relname)
                        and PGC.relnamespace = PGN.oid
			and "_gamersmafia".slon_quote_brute(PGN.nspname) = "_gamersmafia".slon_quote_brute("_gamersmafia".sl_table.tab_nspname);

	for prec in select seq_id from "_gamersmafia".sl_sequence loop
		update "_gamersmafia".sl_sequence set seq_reloid = (select oid from pg_class pc where relkind <> 'S' and not exists (select 1 from "_gamersmafia".sl_sequence t2 where t2.tab_reloid = pc.oid) limit 1)
		where tab_id = prec.seq_id;
	end loop;

        update "_gamersmafia".sl_sequence set
                seq_reloid = PGC.oid
                from pg_catalog.pg_class PGC, pg_catalog.pg_namespace PGN
                where "_gamersmafia".slon_quote_brute("_gamersmafia".sl_sequence.seq_relname) = "_gamersmafia".slon_quote_brute(PGC.relname)
                	and PGC.relnamespace = PGN.oid
			and "_gamersmafia".slon_quote_brute(PGN.nspname) = "_gamersmafia".slon_quote_brute("_gamersmafia".sl_sequence.seq_nspname);

	return 1;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION updatereloid(integer, integer); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION updatereloid(integer, integer) IS 'updateReloid(set_id, only_on_node)

Updates the respective reloids in sl_table and sl_seqeunce based on
their respective FQN';


--
-- Name: upgradeschema(text); Type: FUNCTION; Schema: _gamersmafia; Owner: -
--

CREATE FUNCTION upgradeschema(text) RETURNS text
    AS $_$

declare
        p_old   	alias for $1;
		v_tab_row	record;
begin
	-- If old version is pre-2.0, then we require a special upgrade process
	if p_old like '1.%' then
		raise exception 'Upgrading to Slony-I 2.x requires running slony_upgrade_20';
	end if;

	return p_old;
end;
$_$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION upgradeschema(text); Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON FUNCTION upgradeschema(text) IS 'Called during "update functions" by slonik to perform schema changes';


--
-- Name: sl_action_seq; Type: SEQUENCE; Schema: _gamersmafia; Owner: -
--

CREATE SEQUENCE sl_action_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: SEQUENCE sl_action_seq; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON SEQUENCE sl_action_seq IS 'The sequence to number statements in the transaction logs, so that the replication engines can figure out the "agreeable" order of statements.';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: sl_archive_counter; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_archive_counter (
    ac_num bigint,
    ac_timestamp timestamp without time zone
);


--
-- Name: TABLE sl_archive_counter; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_archive_counter IS 'Table used to generate the log shipping archive number.
';


--
-- Name: COLUMN sl_archive_counter.ac_num; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_archive_counter.ac_num IS 'Counter of SYNC ID used in log shipping as the archive number';


--
-- Name: COLUMN sl_archive_counter.ac_timestamp; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_archive_counter.ac_timestamp IS 'Time at which the archive log was generated on the subscriber';


--
-- Name: sl_config_lock; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_config_lock (
    dummy integer
);


--
-- Name: TABLE sl_config_lock; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_config_lock IS 'This table exists solely to prevent overlapping execution of configuration change procedures and the resulting possible deadlocks.
';


--
-- Name: COLUMN sl_config_lock.dummy; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_config_lock.dummy IS 'No data ever goes in this table so the contents never matter.  Indeed, this column does not really need to exist.';


--
-- Name: sl_confirm; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_confirm (
    con_origin integer,
    con_received integer,
    con_seqno bigint,
    con_timestamp timestamp without time zone DEFAULT (timeofday())::timestamp without time zone
);


--
-- Name: TABLE sl_confirm; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_confirm IS 'Holds confirmation of replication events.  After a period of time, Slony removes old confirmed events from both this table and the sl_event table.';


--
-- Name: COLUMN sl_confirm.con_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_confirm.con_origin IS 'The ID # (from sl_node.no_id) of the source node for this event';


--
-- Name: COLUMN sl_confirm.con_seqno; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_confirm.con_seqno IS 'The ID # for the event';


--
-- Name: COLUMN sl_confirm.con_timestamp; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_confirm.con_timestamp IS 'When this event was confirmed';


--
-- Name: sl_event; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_event (
    ev_origin integer NOT NULL,
    ev_seqno bigint NOT NULL,
    ev_timestamp timestamp without time zone,
    ev_snapshot txid_snapshot,
    ev_type text,
    ev_data1 text,
    ev_data2 text,
    ev_data3 text,
    ev_data4 text,
    ev_data5 text,
    ev_data6 text,
    ev_data7 text,
    ev_data8 text
);


--
-- Name: TABLE sl_event; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_event IS 'Holds information about replication events.  After a period of time, Slony removes old confirmed events from both this table and the sl_confirm table.';


--
-- Name: COLUMN sl_event.ev_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_origin IS 'The ID # (from sl_node.no_id) of the source node for this event';


--
-- Name: COLUMN sl_event.ev_seqno; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_seqno IS 'The ID # for the event';


--
-- Name: COLUMN sl_event.ev_timestamp; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_timestamp IS 'When this event record was created';


--
-- Name: COLUMN sl_event.ev_snapshot; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_snapshot IS 'TXID snapshot on provider node for this event';


--
-- Name: COLUMN sl_event.ev_type; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_type IS 'The type of event this record is for.  
				SYNC				= Synchronise
				STORE_NODE			=
				ENABLE_NODE			=
				DROP_NODE			=
				STORE_PATH			=
				DROP_PATH			=
				STORE_LISTEN		=
				DROP_LISTEN			=
				STORE_SET			=
				DROP_SET			=
				MERGE_SET			=
				SET_ADD_TABLE		=
				SET_ADD_SEQUENCE	=
				STORE_TRIGGER		=
				DROP_TRIGGER		=
				MOVE_SET			=
				ACCEPT_SET			=
				SET_DROP_TABLE			=
				SET_DROP_SEQUENCE		=
				SET_MOVE_TABLE			=
				SET_MOVE_SEQUENCE		=
				FAILOVER_SET		=
				SUBSCRIBE_SET		=
				ENABLE_SUBSCRIPTION	=
				UNSUBSCRIBE_SET		=
				DDL_SCRIPT			=
				ADJUST_SEQ			=
				RESET_CONFIG		=
';


--
-- Name: COLUMN sl_event.ev_data1; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data1 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data2; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data2 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data3; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data3 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data4; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data4 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data5; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data5 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data6; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data6 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data7; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data7 IS 'Data field containing an argument needed to process the event';


--
-- Name: COLUMN sl_event.ev_data8; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_event.ev_data8 IS 'Data field containing an argument needed to process the event';


--
-- Name: sl_event_seq; Type: SEQUENCE; Schema: _gamersmafia; Owner: -
--

CREATE SEQUENCE sl_event_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: SEQUENCE sl_event_seq; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON SEQUENCE sl_event_seq IS 'The sequence for numbering events originating from this node.';


--
-- Name: sl_listen; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_listen (
    li_origin integer NOT NULL,
    li_provider integer NOT NULL,
    li_receiver integer NOT NULL
);


--
-- Name: TABLE sl_listen; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_listen IS 'Indicates how nodes listen to events from other nodes in the Slony-I network.';


--
-- Name: COLUMN sl_listen.li_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_listen.li_origin IS 'The ID # (from sl_node.no_id) of the node this listener is operating on';


--
-- Name: COLUMN sl_listen.li_provider; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_listen.li_provider IS 'The ID # (from sl_node.no_id) of the source node for this listening event';


--
-- Name: COLUMN sl_listen.li_receiver; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_listen.li_receiver IS 'The ID # (from sl_node.no_id) of the target node for this listening event';


--
-- Name: sl_local_node_id; Type: SEQUENCE; Schema: _gamersmafia; Owner: -
--

CREATE SEQUENCE sl_local_node_id
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE -1
    CACHE 1;


--
-- Name: SEQUENCE sl_local_node_id; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON SEQUENCE sl_local_node_id IS 'The local node ID is initialized to -1, meaning that this node is not initialized yet.';


--
-- Name: sl_log_1; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_log_1 (
    log_origin integer,
    log_txid bigint,
    log_tableid integer,
    log_actionseq bigint,
    log_cmdtype character(1),
    log_cmddata text
);


--
-- Name: TABLE sl_log_1; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_log_1 IS 'Stores each change to be propagated to subscriber nodes';


--
-- Name: COLUMN sl_log_1.log_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_1.log_origin IS 'Origin node from which the change came';


--
-- Name: COLUMN sl_log_1.log_txid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_1.log_txid IS 'Transaction ID on the origin node';


--
-- Name: COLUMN sl_log_1.log_tableid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_1.log_tableid IS 'The table ID (from sl_table.tab_id) that this log entry is to affect';


--
-- Name: COLUMN sl_log_1.log_cmdtype; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_1.log_cmdtype IS 'Replication action to take. U = Update, I = Insert, D = DELETE';


--
-- Name: COLUMN sl_log_1.log_cmddata; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_1.log_cmddata IS 'The data needed to perform the log action';


--
-- Name: sl_log_2; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_log_2 (
    log_origin integer,
    log_txid bigint,
    log_tableid integer,
    log_actionseq bigint,
    log_cmdtype character(1),
    log_cmddata text
);


--
-- Name: TABLE sl_log_2; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_log_2 IS 'Stores each change to be propagated to subscriber nodes';


--
-- Name: COLUMN sl_log_2.log_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_2.log_origin IS 'Origin node from which the change came';


--
-- Name: COLUMN sl_log_2.log_txid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_2.log_txid IS 'Transaction ID on the origin node';


--
-- Name: COLUMN sl_log_2.log_tableid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_2.log_tableid IS 'The table ID (from sl_table.tab_id) that this log entry is to affect';


--
-- Name: COLUMN sl_log_2.log_cmdtype; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_2.log_cmdtype IS 'Replication action to take. U = Update, I = Insert, D = DELETE';


--
-- Name: COLUMN sl_log_2.log_cmddata; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_log_2.log_cmddata IS 'The data needed to perform the log action';


--
-- Name: sl_log_status; Type: SEQUENCE; Schema: _gamersmafia; Owner: -
--

CREATE SEQUENCE sl_log_status
    INCREMENT BY 1
    MAXVALUE 3
    MINVALUE 0
    CACHE 1;


--
-- Name: SEQUENCE sl_log_status; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON SEQUENCE sl_log_status IS '
Bit 0x01 determines the currently active log table
Bit 0x02 tells if the engine needs to read both logs
after switching until the old log is clean and truncated.

Possible values:
	0		sl_log_1 active, sl_log_2 clean
	1		sl_log_2 active, sl_log_1 clean
	2		sl_log_1 active, sl_log_2 unknown - cleanup
	3		sl_log_2 active, sl_log_1 unknown - cleanup

This is not yet in use.
';


--
-- Name: sl_node; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_node (
    no_id integer NOT NULL,
    no_active boolean,
    no_comment text
);


--
-- Name: TABLE sl_node; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_node IS 'Holds the list of nodes associated with this namespace.';


--
-- Name: COLUMN sl_node.no_id; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_node.no_id IS 'The unique ID number for the node';


--
-- Name: COLUMN sl_node.no_active; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_node.no_active IS 'Is the node active in replication yet?';


--
-- Name: COLUMN sl_node.no_comment; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_node.no_comment IS 'A human-oriented description of the node';


--
-- Name: sl_nodelock; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_nodelock (
    nl_nodeid integer NOT NULL,
    nl_conncnt integer NOT NULL,
    nl_backendpid integer
);


--
-- Name: TABLE sl_nodelock; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_nodelock IS 'Used to prevent multiple slon instances and to identify the backends to kill in terminateNodeConnections().';


--
-- Name: COLUMN sl_nodelock.nl_nodeid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_nodelock.nl_nodeid IS 'Clients node_id';


--
-- Name: COLUMN sl_nodelock.nl_conncnt; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_nodelock.nl_conncnt IS 'Clients connection number';


--
-- Name: COLUMN sl_nodelock.nl_backendpid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_nodelock.nl_backendpid IS 'PID of database backend owning this lock';


--
-- Name: sl_nodelock_nl_conncnt_seq; Type: SEQUENCE; Schema: _gamersmafia; Owner: -
--

CREATE SEQUENCE sl_nodelock_nl_conncnt_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sl_nodelock_nl_conncnt_seq; Type: SEQUENCE OWNED BY; Schema: _gamersmafia; Owner: -
--

ALTER SEQUENCE sl_nodelock_nl_conncnt_seq OWNED BY sl_nodelock.nl_conncnt;


--
-- Name: sl_path; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_path (
    pa_server integer NOT NULL,
    pa_client integer NOT NULL,
    pa_conninfo text NOT NULL,
    pa_connretry integer
);


--
-- Name: TABLE sl_path; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_path IS 'Holds connection information for the paths between nodes, and the synchronisation delay';


--
-- Name: COLUMN sl_path.pa_server; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_path.pa_server IS 'The Node ID # (from sl_node.no_id) of the data source';


--
-- Name: COLUMN sl_path.pa_client; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_path.pa_client IS 'The Node ID # (from sl_node.no_id) of the data target';


--
-- Name: COLUMN sl_path.pa_conninfo; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_path.pa_conninfo IS 'The PostgreSQL connection string used to connect to the source node.';


--
-- Name: COLUMN sl_path.pa_connretry; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_path.pa_connretry IS 'The synchronisation delay, in seconds';


--
-- Name: sl_registry; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_registry (
    reg_key text NOT NULL,
    reg_int4 integer,
    reg_text text,
    reg_timestamp timestamp without time zone
);


--
-- Name: TABLE sl_registry; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_registry IS 'Stores miscellaneous runtime data';


--
-- Name: COLUMN sl_registry.reg_key; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_registry.reg_key IS 'Unique key of the runtime option';


--
-- Name: COLUMN sl_registry.reg_int4; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_registry.reg_int4 IS 'Option value if type int4';


--
-- Name: COLUMN sl_registry.reg_text; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_registry.reg_text IS 'Option value if type text';


--
-- Name: COLUMN sl_registry.reg_timestamp; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_registry.reg_timestamp IS 'Option value if type timestamp';


--
-- Name: sl_sequence; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_sequence (
    seq_id integer NOT NULL,
    seq_reloid oid NOT NULL,
    seq_relname name NOT NULL,
    seq_nspname name NOT NULL,
    seq_set integer,
    seq_comment text
);


--
-- Name: TABLE sl_sequence; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_sequence IS 'Similar to sl_table, each entry identifies a sequence being replicated.';


--
-- Name: COLUMN sl_sequence.seq_id; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_id IS 'An internally-used ID for Slony-I to use in its sequencing of updates';


--
-- Name: COLUMN sl_sequence.seq_reloid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_reloid IS 'The OID of the sequence object';


--
-- Name: COLUMN sl_sequence.seq_relname; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_relname IS 'The name of the sequence in pg_catalog.pg_class.relname used to recover from a dump/restore cycle';


--
-- Name: COLUMN sl_sequence.seq_nspname; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_nspname IS 'The name of the schema in pg_catalog.pg_namespace.nspname used to recover from a dump/restore cycle';


--
-- Name: COLUMN sl_sequence.seq_set; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_set IS 'Indicates which replication set the object is in';


--
-- Name: COLUMN sl_sequence.seq_comment; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_sequence.seq_comment IS 'A human-oriented comment';


--
-- Name: sl_set; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_set (
    set_id integer NOT NULL,
    set_origin integer,
    set_locked bigint,
    set_comment text
);


--
-- Name: TABLE sl_set; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_set IS 'Holds definitions of replication sets.';


--
-- Name: COLUMN sl_set.set_id; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_set.set_id IS 'A unique ID number for the set.';


--
-- Name: COLUMN sl_set.set_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_set.set_origin IS 'The ID number of the source node for the replication set.';


--
-- Name: COLUMN sl_set.set_locked; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_set.set_locked IS 'Transaction ID where the set was locked.';


--
-- Name: COLUMN sl_set.set_comment; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_set.set_comment IS 'A human-oriented description of the set.';


--
-- Name: sl_seqlastvalue; Type: VIEW; Schema: _gamersmafia; Owner: -
--

CREATE VIEW sl_seqlastvalue AS
    SELECT sq.seq_id, sq.seq_set, sq.seq_reloid, s.set_origin AS seq_origin, sequencelastvalue(((quote_ident((pgn.nspname)::text) || '.'::text) || quote_ident((pgc.relname)::text))) AS seq_last_value FROM sl_sequence sq, sl_set s, pg_class pgc, pg_namespace pgn WHERE (((s.set_id = sq.seq_set) AND (pgc.oid = sq.seq_reloid)) AND (pgn.oid = pgc.relnamespace));


--
-- Name: sl_seqlog; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_seqlog (
    seql_seqid integer,
    seql_origin integer,
    seql_ev_seqno bigint,
    seql_last_value bigint
);


--
-- Name: TABLE sl_seqlog; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_seqlog IS 'Log of Sequence updates';


--
-- Name: COLUMN sl_seqlog.seql_seqid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_seqlog.seql_seqid IS 'Sequence ID';


--
-- Name: COLUMN sl_seqlog.seql_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_seqlog.seql_origin IS 'Publisher node at which the sequence originates';


--
-- Name: COLUMN sl_seqlog.seql_ev_seqno; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_seqlog.seql_ev_seqno IS 'Slony-I Event with which this sequence update is associated';


--
-- Name: COLUMN sl_seqlog.seql_last_value; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_seqlog.seql_last_value IS 'Last value published for this sequence';


--
-- Name: sl_setsync; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_setsync (
    ssy_setid integer NOT NULL,
    ssy_origin integer,
    ssy_seqno bigint,
    ssy_snapshot txid_snapshot,
    ssy_action_list text
);


--
-- Name: TABLE sl_setsync; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_setsync IS 'SYNC information';


--
-- Name: COLUMN sl_setsync.ssy_setid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_setsync.ssy_setid IS 'ID number of the replication set';


--
-- Name: COLUMN sl_setsync.ssy_origin; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_setsync.ssy_origin IS 'ID number of the node';


--
-- Name: COLUMN sl_setsync.ssy_seqno; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_setsync.ssy_seqno IS 'Slony-I sequence number';


--
-- Name: COLUMN sl_setsync.ssy_snapshot; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_setsync.ssy_snapshot IS 'TXID in provider system seen by the event';


--
-- Name: COLUMN sl_setsync.ssy_action_list; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_setsync.ssy_action_list IS 'action list used during the subscription process. At the time a subscriber copies over data from the origin, it sees all tables in a state somewhere between two SYNC events. Therefore this list must contains all log_actionseqs that are visible at that time, whose operations have therefore already been included in the data copied at the time the initial data copy is done.  Those actions may therefore be filtered out of the first SYNC done after subscribing.';


--
-- Name: sl_subscribe; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_subscribe (
    sub_set integer NOT NULL,
    sub_provider integer,
    sub_receiver integer NOT NULL,
    sub_forward boolean,
    sub_active boolean
);


--
-- Name: TABLE sl_subscribe; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_subscribe IS 'Holds a list of subscriptions on sets';


--
-- Name: COLUMN sl_subscribe.sub_set; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_subscribe.sub_set IS 'ID # (from sl_set) of the set being subscribed to';


--
-- Name: COLUMN sl_subscribe.sub_provider; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_subscribe.sub_provider IS 'ID# (from sl_node) of the node providing data';


--
-- Name: COLUMN sl_subscribe.sub_receiver; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_subscribe.sub_receiver IS 'ID# (from sl_node) of the node receiving data from the provider';


--
-- Name: COLUMN sl_subscribe.sub_forward; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_subscribe.sub_forward IS 'Does this provider keep data in sl_log_1/sl_log_2 to allow it to be a provider for other nodes?';


--
-- Name: COLUMN sl_subscribe.sub_active; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_subscribe.sub_active IS 'Has this subscription been activated?  This is not set on the subscriber until AFTER the subscriber has received COPY data from the provider';


--
-- Name: sl_table; Type: TABLE; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE TABLE sl_table (
    tab_id integer NOT NULL,
    tab_reloid oid NOT NULL,
    tab_relname name NOT NULL,
    tab_nspname name NOT NULL,
    tab_set integer,
    tab_idxname name NOT NULL,
    tab_altered boolean NOT NULL,
    tab_comment text
);


--
-- Name: TABLE sl_table; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON TABLE sl_table IS 'Holds information about the tables being replicated.';


--
-- Name: COLUMN sl_table.tab_id; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_id IS 'Unique key for Slony-I to use to identify the table';


--
-- Name: COLUMN sl_table.tab_reloid; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_reloid IS 'The OID of the table in pg_catalog.pg_class.oid';


--
-- Name: COLUMN sl_table.tab_relname; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_relname IS 'The name of the table in pg_catalog.pg_class.relname used to recover from a dump/restore cycle';


--
-- Name: COLUMN sl_table.tab_nspname; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_nspname IS 'The name of the schema in pg_catalog.pg_namespace.nspname used to recover from a dump/restore cycle';


--
-- Name: COLUMN sl_table.tab_set; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_set IS 'ID of the replication set the table is in';


--
-- Name: COLUMN sl_table.tab_idxname; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_idxname IS 'The name of the primary index of the table';


--
-- Name: COLUMN sl_table.tab_altered; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_altered IS 'Has the table been modified for replication?';


--
-- Name: COLUMN sl_table.tab_comment; Type: COMMENT; Schema: _gamersmafia; Owner: -
--

COMMENT ON COLUMN sl_table.tab_comment IS 'Human-oriented description of the table';


SET search_path = archive, pg_catalog;

--
-- Name: pageviews; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);


--
-- Name: tracker_items; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE tracker_items (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone NOT NULL,
    is_tracked boolean NOT NULL,
    notification_sent_on timestamp without time zone
);


--
-- Name: treated_visitors; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE treated_visitors (
    id integer NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);


SET search_path = public, pg_catalog;

--
-- Name: ab_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ab_tests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ab_tests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ab_tests (
    id integer DEFAULT nextval('ab_tests_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    treatments integer NOT NULL,
    finished boolean DEFAULT false NOT NULL,
    minimum_difference numeric(10,2),
    metrics character varying,
    info_url character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    completed_on timestamp without time zone,
    min_difference numeric(10,2) DEFAULT 0.05 NOT NULL,
    cache_conversion_rates character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    dirty boolean DEFAULT true NOT NULL,
    cache_expected_completion_date timestamp without time zone,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: ads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    file character varying,
    link_file character varying,
    html character varying,
    advertiser_id integer
);


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_id_seq OWNED BY ads.id;


--
-- Name: ads_slots; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots (
    id integer NOT NULL,
    name character varying NOT NULL,
    location character varying NOT NULL,
    behaviour_class character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    advertiser_id integer,
    image_dimensions character varying
);


--
-- Name: ads_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_id_seq OWNED BY ads_slots.id;


--
-- Name: ads_slots_instances; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots_instances (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ads_slot_id integer NOT NULL,
    ad_id integer NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: ads_slots_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_instances_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_instances_id_seq OWNED BY ads_slots_instances.id;


--
-- Name: ads_slots_portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots_portals (
    id integer NOT NULL,
    ads_slot_id integer NOT NULL,
    portal_id integer NOT NULL
);


--
-- Name: ads_slots_portals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_portals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_portals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_portals_id_seq OWNED BY ads_slots_portals.id;


--
-- Name: advertisers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advertisers (
    id integer NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    due_on_day smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: advertisers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE advertisers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: advertisers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE advertisers_id_seq OWNED BY advertisers.id;


--
-- Name: allowed_competitions_participants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allowed_competitions_participants (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant_id integer NOT NULL
);


--
-- Name: allowed_competitions_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allowed_competitions_participants_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: allowed_competitions_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allowed_competitions_participants_id_seq OWNED BY allowed_competitions_participants.id;


--
-- Name: anonymous_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE anonymous_users (
    id integer NOT NULL,
    session_id character(32) NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: anonymous_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE anonymous_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: anonymous_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE anonymous_users_id_seq OWNED BY anonymous_users.id;


--
-- Name: autologin_keys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE autologin_keys (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    key character varying(40),
    user_id integer NOT NULL,
    lastused_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: autologin_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE autologin_keys_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: autologin_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE autologin_keys_id_seq OWNED BY autologin_keys.id;


--
-- Name: avatars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE avatars (
    id integer NOT NULL,
    name character varying NOT NULL,
    level integer DEFAULT (-1) NOT NULL,
    path character varying,
    faction_id integer,
    user_id integer,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    submitter_user_id integer NOT NULL
);


--
-- Name: avatars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE avatars_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: avatars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE avatars_id_seq OWNED BY avatars.id;


--
-- Name: babes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE babes (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL
);


--
-- Name: babes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE babes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: babes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE babes_id_seq OWNED BY babes.id;


--
-- Name: ban_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ban_requests (
    id integer NOT NULL,
    user_id integer NOT NULL,
    banned_user_id integer NOT NULL,
    confirming_user_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    confirmed_on timestamp without time zone,
    reason character varying NOT NULL,
    unban_user_id integer,
    unban_confirming_user_id integer,
    reason_unban character varying,
    unban_created_on timestamp without time zone,
    unban_confirmed_on timestamp without time zone
);


--
-- Name: ban_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ban_requests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ban_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ban_requests_id_seq OWNED BY ban_requests.id;


--
-- Name: bazar_districts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bazar_districts (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    icon character varying
);


--
-- Name: bazar_districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bazar_districts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bazar_districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bazar_districts_id_seq OWNED BY bazar_districts.id;


--
-- Name: bets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    bets_category_id integer,
    closes_on timestamp without time zone NOT NULL,
    total_ammount numeric(14,2) DEFAULT 0 NOT NULL,
    winning_bets_option_id integer,
    cancelled boolean DEFAULT false NOT NULL,
    forfeit boolean DEFAULT false NOT NULL,
    tie boolean DEFAULT false NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: bets_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    bets_count integer DEFAULT 0 NOT NULL
);


--
-- Name: bets_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_categories_id_seq OWNED BY bets_categories.id;


--
-- Name: bets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_id_seq OWNED BY bets.id;


--
-- Name: bets_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_options (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    name character varying NOT NULL,
    ammount numeric(14,2)
);


--
-- Name: bets_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_options_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_options_id_seq OWNED BY bets_options.id;


--
-- Name: bets_tickets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_tickets (
    id integer NOT NULL,
    bets_option_id integer NOT NULL,
    user_id integer NOT NULL,
    ammount numeric(14,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: bets_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_tickets_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_tickets_id_seq OWNED BY bets_tickets.id;


--
-- Name: blogentries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blogentries (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    title character varying NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    log character varying,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: blogentries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blogentries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: blogentries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blogentries_id_seq OWNED BY blogentries.id;


--
-- Name: cash_movements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cash_movements (
    id integer NOT NULL,
    description character varying NOT NULL,
    object_id_from integer,
    object_id_to integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ammount numeric(14,2),
    object_id_from_class character varying,
    object_id_to_class character varying
);


--
-- Name: cash_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cash_movements_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: cash_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cash_movements_id_seq OWNED BY cash_movements.id;


SET default_with_oids = true;

--
-- Name: chatlines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE chatlines (
    id integer NOT NULL,
    line character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    sent_to_irc boolean DEFAULT false NOT NULL
);


--
-- Name: chatlines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chatlines_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: chatlines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chatlines_id_seq OWNED BY chatlines.id;


--
-- Name: clans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans (
    id integer NOT NULL,
    name character varying NOT NULL,
    tag character varying NOT NULL,
    simple_mode boolean DEFAULT true NOT NULL,
    website_external character varying,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    irc_channel character varying,
    irc_server character varying,
    o3_websites_dynamicwebsite_id integer,
    logo character varying,
    description text,
    competition_roster character varying,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    members_count integer DEFAULT 0 NOT NULL,
    website_activated boolean DEFAULT false NOT NULL,
    creator_user_id integer,
    cache_popularity integer,
    ranking_popularity_pos integer
);


--
-- Name: clans_friends; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_friends (
    from_clan_id integer NOT NULL,
    from_wants boolean DEFAULT false NOT NULL,
    to_clan_id integer NOT NULL,
    to_wants boolean DEFAULT false NOT NULL,
    id integer NOT NULL
);


--
-- Name: clans_friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_friends_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_friends_id_seq OWNED BY clans_friends.id;


--
-- Name: clans_games; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_games (
    clan_id integer NOT NULL,
    game_id integer NOT NULL
);


--
-- Name: clans_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    clans_groups_type_id integer NOT NULL,
    clan_id integer
);


--
-- Name: clans_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_groups_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_groups_id_seq OWNED BY clans_groups.id;


--
-- Name: clans_groups_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: clans_groups_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_groups_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_groups_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_groups_types_id_seq OWNED BY clans_groups_types.id;


--
-- Name: clans_groups_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups_users (
    clans_group_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: clans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_id_seq OWNED BY clans.id;


SET default_with_oids = false;

--
-- Name: clans_logs_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_logs_entries (
    id integer NOT NULL,
    message character varying,
    clan_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: clans_logs_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_logs_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_logs_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_logs_entries_id_seq OWNED BY clans_logs_entries.id;


--
-- Name: clans_movements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_movements (
    id integer NOT NULL,
    clan_id integer NOT NULL,
    user_id integer,
    direction smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: clans_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_movements_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_movements_id_seq OWNED BY clans_movements.id;


SET default_with_oids = true;

--
-- Name: clans_sponsors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    clan_id integer NOT NULL,
    url character varying,
    image character varying
);


--
-- Name: clans_sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_sponsors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_sponsors_id_seq OWNED BY clans_sponsors.id;


SET default_with_oids = false;

--
-- Name: columns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE columns (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    columns_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: columns_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE columns_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    columns_count integer DEFAULT 0 NOT NULL
);


--
-- Name: columns_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE columns_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: columns_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE columns_categories_id_seq OWNED BY columns_categories.id;


--
-- Name: columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE columns_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE columns_id_seq OWNED BY columns.id;


--
-- Name: comment_violation_opinions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comment_violation_opinions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    comment_id integer NOT NULL,
    cls smallint,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: comment_violation_opinions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comment_violation_opinions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comment_violation_opinions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comment_violation_opinions_id_seq OWNED BY comment_violation_opinions.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    host inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    comment text NOT NULL,
    has_comments_valorations boolean DEFAULT false NOT NULL,
    portal_id integer,
    cache_rating character varying,
    netiquette_violation boolean,
    lastowner_version character varying,
    lastedited_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL,
    random_v numeric DEFAULT random()
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: comments_valorations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments_valorations (
    id integer NOT NULL,
    comment_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    comments_valorations_type_id integer NOT NULL,
    weight real NOT NULL
);


--
-- Name: comments_valorations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_valorations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_valorations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_valorations_id_seq OWNED BY comments_valorations.id;


--
-- Name: comments_valorations_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments_valorations_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    direction smallint NOT NULL
);


--
-- Name: comments_valorations_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_valorations_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_valorations_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_valorations_types_id_seq OWNED BY comments_valorations_types.id;


--
-- Name: competitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    game_id integer NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    rules text,
    competitions_participants_type_id integer NOT NULL,
    default_maps_per_match smallint,
    forced_maps boolean DEFAULT true NOT NULL,
    random_map_selection_mode smallint,
    scoring_mode smallint DEFAULT 0 NOT NULL,
    pro boolean DEFAULT false NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    force_guids boolean DEFAULT false NOT NULL,
    estimated_end_on timestamp without time zone,
    timetable_for_matches smallint DEFAULT 0 NOT NULL,
    timetable_options character varying,
    fee numeric(14,2),
    invitational boolean DEFAULT false NOT NULL,
    competitions_types_options character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    closed_on timestamp without time zone,
    event_id integer,
    topics_category_id integer,
    header_image character varying,
    type character varying NOT NULL,
    send_notifications boolean DEFAULT true NOT NULL
);


--
-- Name: competitions_admins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_admins (
    competition_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: competitions_games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_games_maps (
    competition_id integer NOT NULL,
    games_map_id integer NOT NULL
);


--
-- Name: competitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_id_seq OWNED BY competitions.id;


--
-- Name: competitions_logs_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_logs_entries (
    id integer NOT NULL,
    message character varying,
    competition_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_logs_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_logs_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_logs_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_logs_entries_id_seq OWNED BY competitions_logs_entries.id;


--
-- Name: competitions_matches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant1_id integer,
    participant2_id integer,
    result smallint,
    participant1_confirmed_result boolean DEFAULT false NOT NULL,
    participant2_confirmed_result boolean DEFAULT false NOT NULL,
    admin_confirmed_result boolean DEFAULT false NOT NULL,
    stage smallint DEFAULT 0 NOT NULL,
    maps smallint,
    score_participant1 integer,
    score_participant2 integer,
    accepted boolean DEFAULT true NOT NULL,
    completed_on timestamp without time zone,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    play_on timestamp without time zone,
    event_id integer,
    forfeit_participant1 boolean DEFAULT false NOT NULL,
    forfeit_participant2 boolean DEFAULT false NOT NULL,
    servers character varying,
    ladder_rules character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_clans_players; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_clans_players (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    competitions_participant_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_clans_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_clans_players_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_clans_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_clans_players_id_seq OWNED BY competitions_matches_clans_players.id;


--
-- Name: competitions_matches_games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_games_maps (
    competitions_match_id integer NOT NULL,
    games_map_id integer NOT NULL,
    partial_participant1_score integer,
    partial_participant2_score integer,
    id integer NOT NULL
);


--
-- Name: competitions_matches_games_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_games_maps_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_games_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_games_maps_id_seq OWNED BY competitions_matches_games_maps.id;


--
-- Name: competitions_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_id_seq OWNED BY competitions_matches.id;


--
-- Name: competitions_matches_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_reports (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    report text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_reports_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_reports_id_seq OWNED BY competitions_matches_reports.id;


--
-- Name: competitions_matches_uploads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_uploads (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    file character varying,
    description character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_uploads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_uploads_id_seq OWNED BY competitions_matches_uploads.id;


--
-- Name: competitions_participants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_participants (
    competition_id integer NOT NULL,
    participant_id integer NOT NULL,
    competitions_participants_type_id smallint NOT NULL,
    id integer NOT NULL,
    name character varying NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    ties integer DEFAULT 0 NOT NULL,
    roster character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    points integer,
    "position" integer DEFAULT (random() * (100000)::double precision) NOT NULL
);


--
-- Name: competitions_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_participants_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_participants_id_seq OWNED BY competitions_participants.id;


--
-- Name: competitions_participants_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_participants_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: competitions_participants_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_participants_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_participants_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_participants_types_id_seq OWNED BY competitions_participants_types.id;


--
-- Name: competitions_sponsors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    competition_id integer NOT NULL,
    url character varying,
    image character varying
);


--
-- Name: competitions_sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_sponsors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_sponsors_id_seq OWNED BY competitions_sponsors.id;


--
-- Name: competitions_supervisors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_supervisors (
    competition_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: content_ratings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_ratings (
    id integer NOT NULL,
    user_id integer,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    rating smallint NOT NULL
);


--
-- Name: content_ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_ratings_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_ratings_id_seq OWNED BY content_ratings.id;


--
-- Name: content_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: content_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_types_id_seq OWNED BY content_types.id;


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents (
    id integer NOT NULL,
    content_type_id integer NOT NULL,
    external_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    name character varying NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    game_id integer,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    platform_id integer,
    url character varying,
    user_id integer NOT NULL,
    portal_id integer,
    bazar_district_id integer,
    closed boolean DEFAULT false NOT NULL,
    source character varying
);


--
-- Name: contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_id_seq OWNED BY contents.id;


--
-- Name: contents_locks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_locks (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: contents_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_locks_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_locks_id_seq OWNED BY contents_locks.id;


--
-- Name: contents_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_recommendations (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    sender_user_id integer NOT NULL,
    receiver_user_id integer NOT NULL,
    content_id integer NOT NULL,
    seen_on timestamp without time zone,
    marked_as_bad boolean DEFAULT false NOT NULL,
    confidence double precision,
    expected_rating smallint,
    comment character varying
);


--
-- Name: contents_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_recommendations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_recommendations_id_seq OWNED BY contents_recommendations.id;


--
-- Name: contents_terms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_terms (
    id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contents_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_terms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_terms_id_seq OWNED BY contents_terms.id;


--
-- Name: contents_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_versions (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    data text
);


--
-- Name: contents_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_versions_id_seq OWNED BY contents_versions.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    code character varying,
    name character varying
);


--
-- Name: coverages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE coverages (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    description text NOT NULL,
    main text,
    event_id integer NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: demo_mirrors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demo_mirrors (
    id integer NOT NULL,
    demo_id integer NOT NULL,
    url character varying NOT NULL
);


--
-- Name: demo_mirrors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demo_mirrors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demo_mirrors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demo_mirrors_id_seq OWNED BY demo_mirrors.id;


--
-- Name: demos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demos (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    demos_category_id integer,
    entity1_local_id integer,
    entity2_local_id integer,
    entity1_external character varying,
    entity2_external character varying,
    games_map_id integer,
    event_id integer,
    pov_type smallint,
    pov_entity smallint,
    file character varying,
    file_hash_md5 character varying,
    downloaded_times integer DEFAULT 0 NOT NULL,
    file_size bigint,
    games_mode_id integer,
    games_version_id integer,
    demotype smallint,
    played_on date,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: demos_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demos_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    demos_count integer DEFAULT 0 NOT NULL
);


--
-- Name: demos_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demos_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demos_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demos_categories_id_seq OWNED BY demos_categories.id;


--
-- Name: demos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demos_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demos_id_seq OWNED BY demos.id;


--
-- Name: download_mirrors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE download_mirrors (
    id integer NOT NULL,
    download_id integer NOT NULL,
    url character varying NOT NULL
);


--
-- Name: download_mirrors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE download_mirrors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: download_mirrors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE download_mirrors_id_seq OWNED BY download_mirrors.id;


--
-- Name: downloaded_downloads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloaded_downloads (
    id integer NOT NULL,
    download_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    session_id character varying,
    referer character varying,
    user_id integer,
    download_cookie character varying(32)
);


--
-- Name: downloaded_downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloaded_downloads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloaded_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloaded_downloads_id_seq OWNED BY downloaded_downloads.id;


--
-- Name: downloads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloads (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    downloads_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    file character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    essential boolean DEFAULT false NOT NULL,
    downloaded_times integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: downloads_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloads_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    downloads_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);


--
-- Name: downloads_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloads_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloads_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloads_categories_id_seq OWNED BY downloads_categories.id;


--
-- Name: downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloads_id_seq OWNED BY downloads.id;


--
-- Name: dudes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dudes (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL
);


--
-- Name: dudes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dudes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: dudes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dudes_id_seq OWNED BY dudes.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    description text,
    events_category_id integer,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    website character varying,
    parent_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: events_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    events_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);


--
-- Name: events_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_categories_id_seq OWNED BY events_categories.id;


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: events_news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_news_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_news_id_seq OWNED BY coverages.id;


--
-- Name: events_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events_users (
    event_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: f; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW f AS
    SELECT count(comments.id) AS count FROM comments GROUP BY date_trunc('day'::text, comments.created_on) ORDER BY date_trunc('day'::text, comments.created_on) DESC OFFSET 1 LIMIT 360;


--
-- Name: factions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions (
    id integer NOT NULL,
    name character varying NOT NULL,
    boss_user_id integer,
    underboss_user_id integer,
    building_bottom character varying,
    building_top character varying,
    building_middle character varying,
    description character varying,
    why_join character varying,
    code character varying,
    members_count integer DEFAULT 0 NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    is_platform boolean DEFAULT false NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    cache_member_cohesion numeric
);


--
-- Name: factions_banned_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_banned_users (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying,
    banner_user_id integer NOT NULL
);


--
-- Name: factions_banned_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_banned_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_banned_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_banned_users_id_seq OWNED BY factions_banned_users.id;


--
-- Name: factions_capos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_capos (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: factions_capos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_capos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_capos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_capos_id_seq OWNED BY factions_capos.id;


--
-- Name: factions_editors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_editors (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL,
    content_type_id integer NOT NULL
);


--
-- Name: factions_editors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_editors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_editors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_editors_id_seq OWNED BY factions_editors.id;


--
-- Name: factions_headers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_headers (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    lasttime_used_on timestamp without time zone
);


--
-- Name: factions_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_headers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_headers_id_seq OWNED BY factions_headers.id;


--
-- Name: factions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_id_seq OWNED BY factions.id;


--
-- Name: factions_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_links (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    image character varying
);


--
-- Name: factions_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_links_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_links_id_seq OWNED BY factions_links.id;


--
-- Name: factions_portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_portals (
    faction_id integer NOT NULL,
    portal_id integer NOT NULL
);


SET default_with_oids = true;

--
-- Name: faq_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    "position" integer,
    parent_id integer,
    root_id integer
);


--
-- Name: faq_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE faq_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: faq_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE faq_categories_id_seq OWNED BY faq_categories.id;


--
-- Name: faq_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_entries (
    id integer NOT NULL,
    question character varying NOT NULL,
    answer character varying NOT NULL,
    faq_category_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    "position" integer
);


--
-- Name: faq_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE faq_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: faq_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE faq_entries_id_seq OWNED BY faq_entries.id;


SET default_with_oids = false;

--
-- Name: topics_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    topics_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_topic_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);


--
-- Name: forum_forums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_forums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forum_forums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_forums_id_seq OWNED BY topics_categories.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics (
    id integer NOT NULL,
    title character varying NOT NULL,
    topics_category_id integer,
    main text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    moved_on timestamp without time zone,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    unique_content_id integer
);


--
-- Name: forum_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_topics_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forum_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_topics_id_seq OWNED BY topics.id;


--
-- Name: friends_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE friends_recommendations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    recommended_user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone,
    added_as_friend boolean,
    reason character varying
);


--
-- Name: friends_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE friends_recommendations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: friends_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE friends_recommendations_id_seq OWNED BY friends_recommendations.id;


SET default_with_oids = true;

--
-- Name: friendships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE friendships (
    sender_user_id integer NOT NULL,
    receiver_user_id integer,
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    accepted_on timestamp without time zone,
    receiver_email character varying,
    invitation_text character varying,
    external_invitation_key character(32)
);


--
-- Name: friends_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE friends_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: friends_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE friends_users_id_seq OWNED BY friendships.id;


SET default_with_oids = false;

--
-- Name: funthings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE funthings (
    id integer NOT NULL,
    title character varying NOT NULL,
    description character varying,
    main character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: funthings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE funthings_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: funthings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE funthings_id_seq OWNED BY funthings.id;


SET default_with_oids = true;

--
-- Name: games; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    has_guids boolean DEFAULT false NOT NULL,
    guid_format character varying
);


--
-- Name: games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_id_seq OWNED BY games.id;


SET default_with_oids = false;

--
-- Name: games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_maps (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    download_id integer,
    screenshot character varying
);


--
-- Name: games_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_maps_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_maps_id_seq OWNED BY games_maps.id;


--
-- Name: games_modes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    entity_type smallint
);


--
-- Name: games_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_modes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_modes_id_seq OWNED BY games_modes.id;


--
-- Name: games_platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_platforms (
    game_id integer NOT NULL,
    platform_id integer NOT NULL
);


--
-- Name: games_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_users (
    game_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: games_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_versions (
    id integer NOT NULL,
    version character varying NOT NULL,
    game_id integer NOT NULL
);


--
-- Name: games_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_versions_id_seq OWNED BY games_versions.id;


--
-- Name: global_notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE global_notifications (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    completed_on timestamp without time zone,
    recipient_type character varying,
    title character varying,
    main character varying,
    confirmed boolean DEFAULT false NOT NULL
);


--
-- Name: global_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_notifications_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: global_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE global_notifications_id_seq OWNED BY global_notifications.id;


--
-- Name: global_vars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE global_vars (
    id integer NOT NULL,
    online_anonymous integer DEFAULT 0 NOT NULL,
    online_registered integer DEFAULT 0 NOT NULL,
    svn_revision character varying,
    ads_slots_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    gmtv_channels_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    pending_contents integer DEFAULT 0 NOT NULL,
    portals_updated_on timestamp without time zone
);


--
-- Name: global_vars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_vars_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: global_vars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE global_vars_id_seq OWNED BY global_vars.id;


--
-- Name: gmtv_broadcast_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gmtv_broadcast_messages (
    id integer NOT NULL,
    message character varying NOT NULL,
    starts_on timestamp without time zone DEFAULT now() NOT NULL,
    ends_on timestamp without time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL
);


--
-- Name: gmtv_broadcast_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gmtv_broadcast_messages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gmtv_broadcast_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gmtv_broadcast_messages_id_seq OWNED BY gmtv_broadcast_messages.id;


--
-- Name: gmtv_channels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gmtv_channels (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    faction_id integer,
    file character varying,
    screenshot character varying
);


--
-- Name: gmtv_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gmtv_channels_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gmtv_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gmtv_channels_id_seq OWNED BY gmtv_channels.id;


--
-- Name: goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    owner_user_id integer
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: groups_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups_messages (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    title character varying,
    main character varying,
    parent_id integer,
    root_id integer,
    user_id integer
);


--
-- Name: groups_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_messages_id_seq OWNED BY groups_messages.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE images (
    id integer NOT NULL,
    description character varying,
    file character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    images_category_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: images_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE images_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    images_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);


--
-- Name: images_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE images_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: images_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE images_categories_id_seq OWNED BY images_categories.id;


--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE images_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE images_id_seq OWNED BY images.id;


--
-- Name: interviews; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    interviews_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: interviews_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    interviews_count integer DEFAULT 0 NOT NULL
);


--
-- Name: interviews_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interviews_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: interviews_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interviews_categories_id_seq OWNED BY interviews_categories.id;


--
-- Name: interviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: interviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interviews_id_seq OWNED BY interviews.id;


--
-- Name: ip_bans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ip_bans (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone NOT NULL,
    expires_on timestamp without time zone,
    comment character varying,
    user_id integer
);


--
-- Name: ip_bans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ip_bans_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ip_bans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ip_bans_id_seq OWNED BY ip_bans.id;


--
-- Name: ip_passwords_resets_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ip_passwords_resets_requests (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: ip_passwords_resets_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ip_passwords_resets_requests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ip_passwords_resets_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ip_passwords_resets_requests_id_seq OWNED BY ip_passwords_resets_requests.id;


--
-- Name: macropolls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE macropolls (
    poll_id integer NOT NULL,
    user_id integer,
    answers text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet DEFAULT '0.0.0.0'::inet NOT NULL,
    host character varying,
    id integer NOT NULL
);


--
-- Name: macropolls_2007_1; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE macropolls_2007_1 (
    id integer NOT NULL,
    lacantidaddecontenidosquesepublicanenlawebteparece character varying,
    __sabesquepuedesenviarcontenidos_ character varying,
    __sabesquepuedesdecidirsiuncontenidosepublicaono_ character varying,
    __echasenfaltafuncionesimportantesenlaweb_ character varying,
    __estassuscritoafeedsrss_ character varying,
    participasencompeticiones_clanbase character varying,
    __tegustaelmanga_anime_ character varying,
    larapidezdecargadelaspaginasteparece character varying,
    lasecciondeforosteparece character varying,
    tesientesidentificadoconlaweb character varying,
    prefeririasnovermasqueloscontenidosdetujuego character varying,
    __quecreesquedeberiamosmejorardeformamasurgenteenlaweb_ character varying,
    ellogodelawebtegusta character varying,
    __estasenalgunclan_ character varying,
    eldisenodelawebteparece character varying,
    elnumerodefuncionesdelawebteparece_bis_ character varying,
    laactituddelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __tienesalgunavideoconsola_ character varying,
    siofreciesemosdenuevoelsistemadewebsparaclanes___creesquetuclan character varying,
    sipudiesesleregalariasalwebmasterunbilletea character varying,
    elambienteenloscomentarioses character varying,
    elnumerodefuncionesdelawebteparece character varying,
    seguneltiempoquelededicasalosjuegosteconsiderasunjugador character varying,
    lacantidaddepublicidadqueapareceenlawebteparece character varying,
    lalabordelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __sabesquepuedescreartuspropiascompeticionesoparticiparencompet character varying,
    lascabecerasteparecen character varying,
    tuopiniongeneralsobrelawebes character varying,
    razonprincipalporlaquevisitaslaweb character varying,
    lacalidaddeloscontenidosteparece character varying,
    lasecciondebabes_dudestegusta character varying,
    __quetendriaquetenerlawebparaquefueseperfectaparati_ character varying,
    __deentrelaswebsdejuegosquevisitasfrecuentementedondenossituari character varying,
    user_id integer,
    created_on character varying NOT NULL,
    ipaddr inet NOT NULL,
    host character varying
);


--
-- Name: macropolls_2007_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE macropolls_2007_1_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: macropolls_2007_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE macropolls_2007_1_id_seq OWNED BY macropolls_2007_1.id;


--
-- Name: macropolls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE macropolls_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: macropolls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE macropolls_id_seq OWNED BY macropolls.id;


SET default_with_oids = true;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    id integer NOT NULL,
    user_id_from integer NOT NULL,
    user_id_to integer NOT NULL,
    title character varying NOT NULL,
    message text NOT NULL,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    in_reply_to integer,
    has_replies boolean DEFAULT false NOT NULL,
    message_type smallint DEFAULT 0 NOT NULL,
    sender_deleted boolean DEFAULT false NOT NULL,
    receiver_deleted boolean DEFAULT false NOT NULL,
    thread_id integer
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


SET default_with_oids = false;

--
-- Name: ne_references; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ne_references (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    referenced_on timestamp without time zone NOT NULL,
    entity_class character varying NOT NULL,
    entity_id integer NOT NULL,
    referencer_class character varying NOT NULL,
    referencer_id integer NOT NULL
);


--
-- Name: ne_references_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ne_references_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ne_references_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ne_references_id_seq OWNED BY ne_references.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text,
    approved_by_user_id integer,
    news_category_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: news_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    news_count integer DEFAULT 0 NOT NULL,
    clan_id integer,
    file character varying
);


--
-- Name: news_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: news_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_categories_id_seq OWNED BY news_categories.id;


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_id_seq OWNED BY news.id;


--
-- Name: outstanding_entities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE outstanding_entities (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    portal_id integer,
    active_on date NOT NULL,
    type character varying NOT NULL,
    reason character varying
);


--
-- Name: outstanding_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outstanding_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: outstanding_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outstanding_users_id_seq OWNED BY outstanding_entities.id;


--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE platforms (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL
);


--
-- Name: platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE platforms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE platforms_id_seq OWNED BY platforms.id;


--
-- Name: platforms_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE platforms_users (
    user_id integer NOT NULL,
    platform_id integer NOT NULL
);


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    polls_category_id integer,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    polls_votes_count integer DEFAULT 0 NOT NULL
);


--
-- Name: polls_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    polls_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);


--
-- Name: polls_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_categories_id_seq OWNED BY polls_categories.id;


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_id_seq OWNED BY polls.id;


--
-- Name: polls_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_options (
    id integer NOT NULL,
    poll_id integer NOT NULL,
    name character varying NOT NULL,
    polls_votes_count integer DEFAULT 0 NOT NULL,
    "position" integer
);


--
-- Name: polls_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_options_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_options_id_seq OWNED BY polls_options.id;


--
-- Name: polls_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_votes (
    polls_option_id integer NOT NULL,
    user_id integer,
    id integer NOT NULL,
    remote_ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: polls_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_votes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_votes_id_seq OWNED BY polls_votes.id;


--
-- Name: portal_headers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portal_headers (
    id integer NOT NULL,
    date timestamp without time zone NOT NULL,
    factions_header_id integer NOT NULL,
    portal_id integer NOT NULL
);


--
-- Name: portal_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portal_headers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portal_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portal_headers_id_seq OWNED BY portal_headers.id;


--
-- Name: portal_hits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portal_hits (
    portal_id integer,
    date date DEFAULT (now())::date NOT NULL,
    hits integer DEFAULT 0 NOT NULL,
    id integer NOT NULL
);


--
-- Name: portal_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portal_hits_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portal_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portal_hits_id_seq OWNED BY portal_hits.id;


--
-- Name: portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portals (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    type character varying DEFAULT 'FactionsPortal'::character varying NOT NULL,
    fqdn character varying,
    options character varying,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    skin_id integer,
    default_gmtv_channel_id integer,
    cache_recent_hits_count integer,
    factions_portal_home character varying,
    small_header character varying
);


--
-- Name: portals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portals_id_seq OWNED BY portals.id;


--
-- Name: portals_skins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portals_skins (
    portal_id integer NOT NULL,
    skin_id integer NOT NULL
);


--
-- Name: potds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE potds (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL,
    portal_id integer,
    images_category_id integer,
    term_id integer
);


--
-- Name: potds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE potds_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: potds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE potds_id_seq OWNED BY potds.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    id integer NOT NULL,
    name character varying NOT NULL,
    price numeric(14,2) NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    cls character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: profile_signatures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profile_signatures (
    id integer NOT NULL,
    user_id integer NOT NULL,
    signer_user_id integer NOT NULL,
    signature character varying NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: profile_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE profile_signatures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: profile_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE profile_signatures_id_seq OWNED BY profile_signatures.id;


--
-- Name: publishing_decisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE publishing_decisions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    publish boolean NOT NULL,
    user_weight numeric NOT NULL,
    deny_reason character varying,
    is_right boolean,
    accept_comment character varying
);


--
-- Name: publishing_decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE publishing_decisions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: publishing_decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE publishing_decisions_id_seq OWNED BY publishing_decisions.id;


--
-- Name: publishing_personalities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE publishing_personalities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    content_type_id integer NOT NULL,
    experience numeric DEFAULT 0.0
);


--
-- Name: publishing_personalities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE publishing_personalities_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: publishing_personalities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE publishing_personalities_id_seq OWNED BY publishing_personalities.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions (
    id integer NOT NULL,
    title character varying NOT NULL,
    questions_category_id integer,
    description text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    accepted_answer_comment_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    approved_by_user_id integer,
    ammount numeric(10,2),
    answered_on timestamp without time zone,
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    answer_selected_by_user_id integer
);


--
-- Name: questions_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    questions_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_question_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);


--
-- Name: questions_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE questions_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: questions_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE questions_categories_id_seq OWNED BY questions_categories.id;


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE questions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE questions_id_seq OWNED BY questions.id;


--
-- Name: recruitment_ads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE recruitment_ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    clan_id integer,
    game_id integer NOT NULL,
    levels character varying,
    country_id integer,
    main text,
    deleted boolean DEFAULT false NOT NULL,
    title character varying NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: recruitment_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recruitment_ads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: recruitment_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recruitment_ads_id_seq OWNED BY recruitment_ads.id;


--
-- Name: refered_hits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE refered_hits (
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet NOT NULL,
    referer character varying NOT NULL,
    id integer NOT NULL
);


--
-- Name: refered_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE refered_hits_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: refered_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE refered_hits_id_seq OWNED BY refered_hits.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    reviews_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    home_image character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: reviews_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    reviews_count integer DEFAULT 0 NOT NULL
);


--
-- Name: reviews_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reviews_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reviews_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reviews_categories_id_seq OWNED BY reviews_categories.id;


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reviews_id_seq OWNED BY reviews.id;


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_info (
    version integer NOT NULL,
    "_Slony-I_gamersmafia_rowID" bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sent_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sent_emails (
    id integer NOT NULL,
    message_key character varying NOT NULL,
    title character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    first_read_on timestamp without time zone,
    sender character varying,
    recipient character varying,
    recipient_user_id integer,
    global_notification_id integer
);


--
-- Name: sent_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sent_emails_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sent_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sent_emails_id_seq OWNED BY sent_emails.id;


--
-- Name: silenced_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE silenced_emails (
    id integer NOT NULL,
    email character varying NOT NULL
);


--
-- Name: silenced_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE silenced_emails_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: silenced_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE silenced_emails_id_seq OWNED BY silenced_emails.id;


--
-- Name: skin_textures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE skin_textures (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    skin_id integer NOT NULL,
    texture_id integer NOT NULL,
    textured_element_position integer NOT NULL,
    texture_skin_position integer NOT NULL,
    user_config character varying,
    element character varying NOT NULL
);


--
-- Name: skin_textures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE skin_textures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: skin_textures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE skin_textures_id_seq OWNED BY skin_textures.id;


--
-- Name: skins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE skins (
    id integer NOT NULL,
    name character varying NOT NULL,
    hid character varying NOT NULL,
    user_id integer NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    type character varying NOT NULL,
    file character varying,
    version integer DEFAULT 0 NOT NULL,
    intelliskin_header character varying,
    intelliskin_favicon character varying
);


--
-- Name: skins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE skins_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: skins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE skins_id_seq OWNED BY skins.id;


--
-- Name: slog_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slog_entries (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    type_id integer NOT NULL,
    info character varying NOT NULL,
    headline character varying NOT NULL,
    request text,
    reporter_user_id integer,
    reviewer_user_id integer,
    long_version character varying,
    short_version character varying,
    completed_on timestamp without time zone,
    scope integer
);


--
-- Name: slog_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE slog_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: slog_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE slog_entries_id_seq OWNED BY slog_entries.id;


--
-- Name: slog_visits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slog_visits (
    user_id integer NOT NULL,
    lastvisit_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: sold_products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sold_products (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    price_paid numeric(14,2) NOT NULL,
    used boolean DEFAULT false NOT NULL,
    type character varying
);


--
-- Name: sold_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sold_products_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sold_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sold_products_id_seq OWNED BY sold_products.id;


--
-- Name: terms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE terms (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description character varying,
    parent_id integer,
    game_id integer,
    platform_id integer,
    bazar_district_id integer,
    clan_id integer,
    contents_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    comments_count integer DEFAULT 0 NOT NULL,
    root_id integer,
    taxonomy character varying
);


--
-- Name: terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE terms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE terms_id_seq OWNED BY terms.id;


--
-- Name: textures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE textures (
    id integer NOT NULL,
    name character varying,
    generator character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    valid_element_selectors character varying
);


--
-- Name: textures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE textures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: textures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE textures_id_seq OWNED BY textures.id;


SET default_with_oids = true;

--
-- Name: tracker_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracker_items (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    is_tracked boolean DEFAULT false NOT NULL,
    notification_sent_on timestamp without time zone
);


--
-- Name: tracker_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracker_items_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tracker_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracker_items_id_seq OWNED BY tracker_items.id;


--
-- Name: treated_visitors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE treated_visitors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


SET default_with_oids = false;

--
-- Name: treated_visitors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE treated_visitors (
    id integer DEFAULT nextval('treated_visitors_id_seq'::regclass) NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);


--
-- Name: tutorials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tutorials (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    tutorials_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: tutorials_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tutorials_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    tutorials_count integer DEFAULT 0
);


--
-- Name: tutorials_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tutorials_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tutorials_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tutorials_categories_id_seq OWNED BY tutorials_categories.id;


--
-- Name: tutorials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tutorials_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tutorials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tutorials_id_seq OWNED BY tutorials.id;


--
-- Name: user_login_changes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_login_changes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    old_login character varying NOT NULL
);


--
-- Name: user_login_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_login_changes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: user_login_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_login_changes_id_seq OWNED BY user_login_changes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(80),
    password character varying(40),
    validkey character varying(40),
    email character varying(100) DEFAULT ''::character varying NOT NULL,
    newemail character varying(100),
    ipaddr character varying(15) DEFAULT ''::character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    firstname character varying DEFAULT ''::character varying,
    lastname character varying DEFAULT ''::character varying,
    image bytea,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    faction_id integer,
    faction_last_changed_on timestamp without time zone,
    avatar_id integer,
    city character varying,
    homepage character varying,
    sex smallint,
    msn character varying,
    icq character varying,
    send_global_announces boolean DEFAULT true NOT NULL,
    birthday date,
    cache_karma_points integer,
    irc character varying,
    country_id integer,
    photo character varying,
    hw_mouse character varying,
    hw_processor character varying,
    hw_motherboard character varying,
    hw_ram character varying,
    hw_hdd character varying,
    hw_graphiccard character varying,
    hw_soundcard character varying,
    hw_headphones character varying,
    hw_monitor character varying,
    hw_connection character varying,
    description text,
    is_superadmin boolean DEFAULT false NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    referer_user_id integer,
    cache_faith_points integer,
    notifications_global boolean DEFAULT true NOT NULL,
    notifications_newmessages boolean DEFAULT true NOT NULL,
    notifications_newregistrations boolean DEFAULT true NOT NULL,
    notifications_trackerupdates boolean DEFAULT true NOT NULL,
    xfire character varying,
    cache_unread_messages integer DEFAULT 0,
    resurrected_by_user_id integer,
    resurrection_started_on timestamp without time zone,
    using_tracker boolean DEFAULT false NOT NULL,
    secret character(32),
    cash numeric(14,2) DEFAULT 0.00 NOT NULL,
    lastcommented_on timestamp without time zone,
    global_bans integer DEFAULT 0 NOT NULL,
    last_clan_id integer,
    antiflood_level smallint DEFAULT (-1) NOT NULL,
    last_competition_id integer,
    competition_roster character varying,
    enable_competition_indicator boolean DEFAULT false NOT NULL,
    is_hq boolean DEFAULT false NOT NULL,
    enable_profile_signatures boolean DEFAULT false NOT NULL,
    profile_signatures_count integer DEFAULT 0 NOT NULL,
    wii_code character(16),
    email_public boolean DEFAULT false NOT NULL,
    gamertag character varying,
    googletalk character varying,
    yahoo_im character varying,
    notifications_newprofilesignature boolean DEFAULT true NOT NULL,
    tracker_autodelete_old_contents boolean DEFAULT true NOT NULL,
    comment_adds_to_tracker_enabled boolean DEFAULT true NOT NULL,
    cache_remaining_rating_slots integer,
    has_seen_tour boolean DEFAULT false NOT NULL,
    is_bot boolean DEFAULT false NOT NULL,
    admin_permissions character varying DEFAULT '00000'::bpchar NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_is_faction_leader boolean DEFAULT false NOT NULL,
    profile_last_updated_on timestamp without time zone,
    visitor_id character varying,
    comments_valorations_type_id integer,
    comments_valorations_strength numeric(10,2),
    enable_comments_sig boolean DEFAULT false NOT NULL,
    comments_sig character varying,
    comment_show_sigs boolean,
    has_new_friend_requests boolean DEFAULT false NOT NULL,
    default_portal character varying,
    emblems_mask character varying,
    random_id double precision DEFAULT random(),
    is_staff boolean DEFAULT false NOT NULL,
    pending_slog integer DEFAULT 0 NOT NULL,
    ranking_karma_pos integer,
    ranking_faith_pos integer,
    ranking_popularity_pos integer,
    cache_popularity integer,
    login_is_ne_unfriendly boolean DEFAULT false NOT NULL
);


--
-- Name: users_actions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_actions (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    type_id integer NOT NULL,
    data character varying,
    object_id integer
);


--
-- Name: users_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_actions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_actions_id_seq OWNED BY users_actions.id;


--
-- Name: users_contents_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_contents_tags_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_contents_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_contents_tags (
    id integer DEFAULT nextval('users_contents_tags_id_seq'::regclass) NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    original_name character varying NOT NULL
);


--
-- Name: users_emblems; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_emblems (
    id integer NOT NULL,
    created_on date DEFAULT (now())::date NOT NULL,
    user_id integer,
    emblem character varying NOT NULL,
    details character varying
);


--
-- Name: users_emblems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_emblems_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_emblems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_emblems_id_seq OWNED BY users_emblems.id;


--
-- Name: users_guids; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_guids (
    id integer NOT NULL,
    guid character varying NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying
);


--
-- Name: users_guids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_guids_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_guids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_guids_id_seq OWNED BY users_guids.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_lastseen_ips; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_lastseen_ips (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    lastseen_on timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    ip inet NOT NULL
);


--
-- Name: users_lastseen_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_lastseen_ips_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_lastseen_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_lastseen_ips_id_seq OWNED BY users_lastseen_ips.id;


--
-- Name: users_newsfeeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_newsfeeds (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    summary character varying NOT NULL,
    users_action_id integer
);


--
-- Name: users_newsfeeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_newsfeeds_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_newsfeeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_newsfeeds_id_seq OWNED BY users_newsfeeds.id;


--
-- Name: users_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    value character varying
);


--
-- Name: users_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_preferences_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_preferences_id_seq OWNED BY users_preferences.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_roles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role character varying NOT NULL,
    role_data character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: users_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_roles_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_roles_id_seq OWNED BY users_roles.id;


SET search_path = stats, pg_catalog;

--
-- Name: ads; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    referer character varying,
    user_id integer,
    user_agent character varying,
    portal_id integer,
    url character varying NOT NULL,
    element_id character varying,
    ip inet NOT NULL,
    visitor_id character varying,
    session_id character varying
);


--
-- Name: ads_daily; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE ads_daily (
    id integer NOT NULL,
    ads_slots_instance_id integer,
    created_on date NOT NULL,
    hits integer NOT NULL,
    ctr double precision NOT NULL,
    pageviews integer NOT NULL
);


--
-- Name: ads_daily_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE ads_daily_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_daily_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE ads_daily_id_seq OWNED BY ads_daily.id;


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE ads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE ads_id_seq OWNED BY ads.id;


--
-- Name: bandit_treatments; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE bandit_treatments (
    id integer NOT NULL,
    behaviour_class character varying NOT NULL,
    abtest_treatment character varying NOT NULL,
    round integer DEFAULT (-1) NOT NULL,
    lever0_reward character varying,
    lever1_reward character varying,
    lever2_reward character varying,
    lever3_reward character varying,
    lever4_reward character varying,
    lever5_reward character varying,
    lever6_reward character varying,
    lever7_reward character varying,
    lever8_reward character varying,
    lever9_reward character varying,
    lever10_reward character varying,
    lever11_reward character varying,
    lever12_reward character varying,
    lever13_reward character varying,
    lever14_reward character varying,
    lever15_reward character varying,
    lever16_reward character varying,
    lever17_reward character varying,
    lever18_reward character varying,
    lever19_reward character varying,
    lever20_reward character varying
);


--
-- Name: bandit_treatments_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE bandit_treatments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bandit_treatments_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE bandit_treatments_id_seq OWNED BY bandit_treatments.id;


--
-- Name: bets_results; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE bets_results (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    user_id integer NOT NULL,
    net_ammount numeric(10,2)
);


--
-- Name: bets_results_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE bets_results_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_results_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE bets_results_id_seq OWNED BY bets_results.id;


--
-- Name: clans_daily_stats; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE clans_daily_stats (
    id integer NOT NULL,
    clan_id integer,
    created_on date NOT NULL,
    popularity integer
);


--
-- Name: clans_daily_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE clans_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_daily_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE clans_daily_stats_id_seq OWNED BY clans_daily_stats.id;


--
-- Name: dates; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE dates (
    date date NOT NULL
);


--
-- Name: general; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE general (
    created_on date DEFAULT (now())::date NOT NULL,
    users_total integer DEFAULT 0 NOT NULL,
    users_confirmed integer DEFAULT 0 NOT NULL,
    users_active integer DEFAULT 0 NOT NULL,
    users_banned integer DEFAULT 0 NOT NULL,
    users_disabled integer DEFAULT 0 NOT NULL,
    karma_diff integer DEFAULT 0.0 NOT NULL,
    faith_diff integer DEFAULT 0 NOT NULL,
    cash_diff numeric(10,4) DEFAULT 0 NOT NULL,
    new_comments integer DEFAULT 0 NOT NULL,
    refered_hits integer DEFAULT 0 NOT NULL,
    avg_users_online double precision DEFAULT 0 NOT NULL,
    users_unconfirmed integer DEFAULT 0 NOT NULL,
    users_zombie integer DEFAULT 0 NOT NULL,
    users_resurrected integer DEFAULT 0 NOT NULL,
    users_shadow integer DEFAULT 0 NOT NULL,
    users_deleted integer DEFAULT 0 NOT NULL,
    users_unconfirmed_1w integer DEFAULT 0 NOT NULL,
    users_unconfirmed_2w integer DEFAULT 0 NOT NULL,
    new_clans integer,
    new_closed_topics integer,
    new_clans_portals integer,
    avg_page_render_time real,
    users_generating_karma integer,
    karma_per_user real,
    stddev_page_render_time real,
    active_factions_portals integer,
    completed_competitions_matches integer,
    active_clans_portals integer,
    proxy_errors integer,
    new_factions integer,
    http_401 integer,
    http_500 integer,
    http_404 integer,
    avg_db_queries_per_request double precision,
    stddev_db_queries_per_request double precision,
    requests integer,
    database_size bigint,
    sent_emails integer,
    downloaded_downloads_count integer,
    users_refered_today integer
);


--
-- Name: pageloadtime; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE pageloadtime (
    controller character varying,
    action character varying,
    "time" numeric(10,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    id integer NOT NULL,
    portal_id integer,
    http_status integer,
    db_queries integer,
    db_rows integer
);


--
-- Name: pageloadtime_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE pageloadtime_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pageloadtime_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE pageloadtime_id_seq OWNED BY pageloadtime.id;


--
-- Name: pageviews; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);


--
-- Name: pageviews_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE pageviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pageviews_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE pageviews_id_seq OWNED BY pageviews.id;


--
-- Name: portals; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE portals (
    id integer NOT NULL,
    created_on date NOT NULL,
    portal_id integer,
    karma integer NOT NULL,
    pageviews integer,
    visits integer,
    unique_visitors integer,
    unique_visitors_reg integer
);


--
-- Name: portals_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE portals_stats_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portals_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE portals_stats_id_seq OWNED BY portals.id;


--
-- Name: users_daily_stats; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE users_daily_stats (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on date NOT NULL,
    karma integer,
    faith integer,
    popularity integer
);


--
-- Name: users_daily_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE users_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_daily_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE users_daily_stats_id_seq OWNED BY users_daily_stats.id;


--
-- Name: users_karma_daily_by_portal; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE users_karma_daily_by_portal (
    id integer NOT NULL,
    user_id integer NOT NULL,
    portal_id integer,
    karma integer,
    created_on date NOT NULL
);


--
-- Name: users_karma_daily_by_portal_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE users_karma_daily_by_portal_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_karma_daily_by_portal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE users_karma_daily_by_portal_id_seq OWNED BY users_karma_daily_by_portal.id;


SET search_path = _gamersmafia, pg_catalog;

--
-- Name: nl_conncnt; Type: DEFAULT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE sl_nodelock ALTER COLUMN nl_conncnt SET DEFAULT nextval('sl_nodelock_nl_conncnt_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots ALTER COLUMN id SET DEFAULT nextval('ads_slots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots_instances ALTER COLUMN id SET DEFAULT nextval('ads_slots_instances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots_portals ALTER COLUMN id SET DEFAULT nextval('ads_slots_portals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE advertisers ALTER COLUMN id SET DEFAULT nextval('advertisers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allowed_competitions_participants ALTER COLUMN id SET DEFAULT nextval('allowed_competitions_participants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE anonymous_users ALTER COLUMN id SET DEFAULT nextval('anonymous_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE autologin_keys ALTER COLUMN id SET DEFAULT nextval('autologin_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE avatars ALTER COLUMN id SET DEFAULT nextval('avatars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE babes ALTER COLUMN id SET DEFAULT nextval('babes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ban_requests ALTER COLUMN id SET DEFAULT nextval('ban_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bazar_districts ALTER COLUMN id SET DEFAULT nextval('bazar_districts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets ALTER COLUMN id SET DEFAULT nextval('bets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_categories ALTER COLUMN id SET DEFAULT nextval('bets_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_options ALTER COLUMN id SET DEFAULT nextval('bets_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_tickets ALTER COLUMN id SET DEFAULT nextval('bets_tickets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE blogentries ALTER COLUMN id SET DEFAULT nextval('blogentries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cash_movements ALTER COLUMN id SET DEFAULT nextval('cash_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE chatlines ALTER COLUMN id SET DEFAULT nextval('chatlines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans ALTER COLUMN id SET DEFAULT nextval('clans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_friends ALTER COLUMN id SET DEFAULT nextval('clans_friends_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_groups ALTER COLUMN id SET DEFAULT nextval('clans_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_groups_types ALTER COLUMN id SET DEFAULT nextval('clans_groups_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_logs_entries ALTER COLUMN id SET DEFAULT nextval('clans_logs_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_movements ALTER COLUMN id SET DEFAULT nextval('clans_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_sponsors ALTER COLUMN id SET DEFAULT nextval('clans_sponsors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE columns ALTER COLUMN id SET DEFAULT nextval('columns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE columns_categories ALTER COLUMN id SET DEFAULT nextval('columns_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comment_violation_opinions ALTER COLUMN id SET DEFAULT nextval('comment_violation_opinions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments_valorations ALTER COLUMN id SET DEFAULT nextval('comments_valorations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments_valorations_types ALTER COLUMN id SET DEFAULT nextval('comments_valorations_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions ALTER COLUMN id SET DEFAULT nextval('competitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_logs_entries ALTER COLUMN id SET DEFAULT nextval('competitions_logs_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches ALTER COLUMN id SET DEFAULT nextval('competitions_matches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_clans_players ALTER COLUMN id SET DEFAULT nextval('competitions_matches_clans_players_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_games_maps ALTER COLUMN id SET DEFAULT nextval('competitions_matches_games_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_reports ALTER COLUMN id SET DEFAULT nextval('competitions_matches_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_uploads ALTER COLUMN id SET DEFAULT nextval('competitions_matches_uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_participants ALTER COLUMN id SET DEFAULT nextval('competitions_participants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_participants_types ALTER COLUMN id SET DEFAULT nextval('competitions_participants_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_sponsors ALTER COLUMN id SET DEFAULT nextval('competitions_sponsors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_ratings ALTER COLUMN id SET DEFAULT nextval('content_ratings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_types ALTER COLUMN id SET DEFAULT nextval('content_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents ALTER COLUMN id SET DEFAULT nextval('contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_locks ALTER COLUMN id SET DEFAULT nextval('contents_locks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_recommendations ALTER COLUMN id SET DEFAULT nextval('contents_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_terms ALTER COLUMN id SET DEFAULT nextval('contents_terms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_versions ALTER COLUMN id SET DEFAULT nextval('contents_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE coverages ALTER COLUMN id SET DEFAULT nextval('events_news_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demo_mirrors ALTER COLUMN id SET DEFAULT nextval('demo_mirrors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demos ALTER COLUMN id SET DEFAULT nextval('demos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demos_categories ALTER COLUMN id SET DEFAULT nextval('demos_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE download_mirrors ALTER COLUMN id SET DEFAULT nextval('download_mirrors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloaded_downloads ALTER COLUMN id SET DEFAULT nextval('downloaded_downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloads ALTER COLUMN id SET DEFAULT nextval('downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloads_categories ALTER COLUMN id SET DEFAULT nextval('downloads_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE dudes ALTER COLUMN id SET DEFAULT nextval('dudes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE events_categories ALTER COLUMN id SET DEFAULT nextval('events_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions ALTER COLUMN id SET DEFAULT nextval('factions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_banned_users ALTER COLUMN id SET DEFAULT nextval('factions_banned_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_capos ALTER COLUMN id SET DEFAULT nextval('factions_capos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_editors ALTER COLUMN id SET DEFAULT nextval('factions_editors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_headers ALTER COLUMN id SET DEFAULT nextval('factions_headers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_links ALTER COLUMN id SET DEFAULT nextval('factions_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE faq_categories ALTER COLUMN id SET DEFAULT nextval('faq_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE faq_entries ALTER COLUMN id SET DEFAULT nextval('faq_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE friends_recommendations ALTER COLUMN id SET DEFAULT nextval('friends_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE friendships ALTER COLUMN id SET DEFAULT nextval('friends_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE funthings ALTER COLUMN id SET DEFAULT nextval('funthings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_maps ALTER COLUMN id SET DEFAULT nextval('games_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_modes ALTER COLUMN id SET DEFAULT nextval('games_modes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_versions ALTER COLUMN id SET DEFAULT nextval('games_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE global_notifications ALTER COLUMN id SET DEFAULT nextval('global_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE global_vars ALTER COLUMN id SET DEFAULT nextval('global_vars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gmtv_broadcast_messages ALTER COLUMN id SET DEFAULT nextval('gmtv_broadcast_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gmtv_channels ALTER COLUMN id SET DEFAULT nextval('gmtv_channels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE groups_messages ALTER COLUMN id SET DEFAULT nextval('groups_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE images ALTER COLUMN id SET DEFAULT nextval('images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE images_categories ALTER COLUMN id SET DEFAULT nextval('images_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE interviews ALTER COLUMN id SET DEFAULT nextval('interviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE interviews_categories ALTER COLUMN id SET DEFAULT nextval('interviews_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ip_bans ALTER COLUMN id SET DEFAULT nextval('ip_bans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ip_passwords_resets_requests ALTER COLUMN id SET DEFAULT nextval('ip_passwords_resets_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE macropolls ALTER COLUMN id SET DEFAULT nextval('macropolls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE macropolls_2007_1 ALTER COLUMN id SET DEFAULT nextval('macropolls_2007_1_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ne_references ALTER COLUMN id SET DEFAULT nextval('ne_references_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE news ALTER COLUMN id SET DEFAULT nextval('news_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE news_categories ALTER COLUMN id SET DEFAULT nextval('news_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE outstanding_entities ALTER COLUMN id SET DEFAULT nextval('outstanding_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE platforms ALTER COLUMN id SET DEFAULT nextval('platforms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls ALTER COLUMN id SET DEFAULT nextval('polls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_categories ALTER COLUMN id SET DEFAULT nextval('polls_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_options ALTER COLUMN id SET DEFAULT nextval('polls_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_votes ALTER COLUMN id SET DEFAULT nextval('polls_votes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portal_headers ALTER COLUMN id SET DEFAULT nextval('portal_headers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portal_hits ALTER COLUMN id SET DEFAULT nextval('portal_hits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portals ALTER COLUMN id SET DEFAULT nextval('portals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE potds ALTER COLUMN id SET DEFAULT nextval('potds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE profile_signatures ALTER COLUMN id SET DEFAULT nextval('profile_signatures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE publishing_decisions ALTER COLUMN id SET DEFAULT nextval('publishing_decisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE publishing_personalities ALTER COLUMN id SET DEFAULT nextval('publishing_personalities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE questions ALTER COLUMN id SET DEFAULT nextval('questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE questions_categories ALTER COLUMN id SET DEFAULT nextval('questions_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE recruitment_ads ALTER COLUMN id SET DEFAULT nextval('recruitment_ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE refered_hits ALTER COLUMN id SET DEFAULT nextval('refered_hits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reviews ALTER COLUMN id SET DEFAULT nextval('reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reviews_categories ALTER COLUMN id SET DEFAULT nextval('reviews_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sent_emails ALTER COLUMN id SET DEFAULT nextval('sent_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE silenced_emails ALTER COLUMN id SET DEFAULT nextval('silenced_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE skin_textures ALTER COLUMN id SET DEFAULT nextval('skin_textures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE skins ALTER COLUMN id SET DEFAULT nextval('skins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE slog_entries ALTER COLUMN id SET DEFAULT nextval('slog_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sold_products ALTER COLUMN id SET DEFAULT nextval('sold_products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE terms ALTER COLUMN id SET DEFAULT nextval('terms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE textures ALTER COLUMN id SET DEFAULT nextval('textures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE topics ALTER COLUMN id SET DEFAULT nextval('forum_topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE topics_categories ALTER COLUMN id SET DEFAULT nextval('forum_forums_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tracker_items ALTER COLUMN id SET DEFAULT nextval('tracker_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tutorials ALTER COLUMN id SET DEFAULT nextval('tutorials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tutorials_categories ALTER COLUMN id SET DEFAULT nextval('tutorials_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_login_changes ALTER COLUMN id SET DEFAULT nextval('user_login_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_actions ALTER COLUMN id SET DEFAULT nextval('users_actions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_emblems ALTER COLUMN id SET DEFAULT nextval('users_emblems_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_guids ALTER COLUMN id SET DEFAULT nextval('users_guids_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_lastseen_ips ALTER COLUMN id SET DEFAULT nextval('users_lastseen_ips_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_newsfeeds ALTER COLUMN id SET DEFAULT nextval('users_newsfeeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_preferences ALTER COLUMN id SET DEFAULT nextval('users_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_roles ALTER COLUMN id SET DEFAULT nextval('users_roles_id_seq'::regclass);


SET search_path = stats, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE ads_daily ALTER COLUMN id SET DEFAULT nextval('ads_daily_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE bandit_treatments ALTER COLUMN id SET DEFAULT nextval('bandit_treatments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE bets_results ALTER COLUMN id SET DEFAULT nextval('bets_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE clans_daily_stats ALTER COLUMN id SET DEFAULT nextval('clans_daily_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE pageloadtime ALTER COLUMN id SET DEFAULT nextval('pageloadtime_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE pageviews ALTER COLUMN id SET DEFAULT nextval('pageviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE portals ALTER COLUMN id SET DEFAULT nextval('portals_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE users_daily_stats ALTER COLUMN id SET DEFAULT nextval('users_daily_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE users_karma_daily_by_portal ALTER COLUMN id SET DEFAULT nextval('users_karma_daily_by_portal_id_seq'::regclass);


SET search_path = _gamersmafia, pg_catalog;

--
-- Name: sl_event-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_event
    ADD CONSTRAINT "sl_event-pkey" PRIMARY KEY (ev_origin, ev_seqno);


--
-- Name: sl_listen-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_listen
    ADD CONSTRAINT "sl_listen-pkey" PRIMARY KEY (li_origin, li_provider, li_receiver);


--
-- Name: sl_node-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_node
    ADD CONSTRAINT "sl_node-pkey" PRIMARY KEY (no_id);


--
-- Name: sl_nodelock-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_nodelock
    ADD CONSTRAINT "sl_nodelock-pkey" PRIMARY KEY (nl_nodeid, nl_conncnt);


--
-- Name: sl_path-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_path
    ADD CONSTRAINT "sl_path-pkey" PRIMARY KEY (pa_server, pa_client);


--
-- Name: sl_registry_pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_registry
    ADD CONSTRAINT sl_registry_pkey PRIMARY KEY (reg_key);


--
-- Name: sl_sequence-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_sequence
    ADD CONSTRAINT "sl_sequence-pkey" PRIMARY KEY (seq_id);


--
-- Name: sl_sequence_seq_reloid_key; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_sequence
    ADD CONSTRAINT sl_sequence_seq_reloid_key UNIQUE (seq_reloid);


--
-- Name: sl_set-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_set
    ADD CONSTRAINT "sl_set-pkey" PRIMARY KEY (set_id);


--
-- Name: sl_setsync-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_setsync
    ADD CONSTRAINT "sl_setsync-pkey" PRIMARY KEY (ssy_setid);


--
-- Name: sl_subscribe-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_subscribe
    ADD CONSTRAINT "sl_subscribe-pkey" PRIMARY KEY (sub_receiver, sub_set);


--
-- Name: sl_table-pkey; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_table
    ADD CONSTRAINT "sl_table-pkey" PRIMARY KEY (tab_id);


--
-- Name: sl_table_tab_reloid_key; Type: CONSTRAINT; Schema: _gamersmafia; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sl_table
    ADD CONSTRAINT sl_table_tab_reloid_key UNIQUE (tab_reloid);


SET search_path = archive, pg_catalog;

--
-- Name: pageviews_pkey; Type: CONSTRAINT; Schema: archive; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviews_pkey PRIMARY KEY (id);


--
-- Name: treated_visitors_pkey; Type: CONSTRAINT; Schema: archive; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);


SET search_path = public, pg_catalog;

--
-- Name: ab_tests_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_name_key UNIQUE (name);


--
-- Name: ab_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_pkey PRIMARY KEY (id);


--
-- Name: ads_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_name_key UNIQUE (name);


--
-- Name: ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots_instances
    ADD CONSTRAINT ads_slots_instances_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_name_key UNIQUE (name);


--
-- Name: ads_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots_portals
    ADD CONSTRAINT ads_slots_portals_pkey PRIMARY KEY (id);


--
-- Name: advertisers_email_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_email_key UNIQUE (email);


--
-- Name: advertisers_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_name_key UNIQUE (name);


--
-- Name: advertisers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_pkey PRIMARY KEY (id);


--
-- Name: allowed_competitions_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allowed_competitions_participants
    ADD CONSTRAINT allowed_competitions_participants_pkey PRIMARY KEY (id);


--
-- Name: anonymous_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY anonymous_users
    ADD CONSTRAINT anonymous_users_pkey PRIMARY KEY (id);


--
-- Name: anonymous_users_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY anonymous_users
    ADD CONSTRAINT anonymous_users_session_id_key UNIQUE (session_id);


--
-- Name: autologin_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY autologin_keys
    ADD CONSTRAINT autologin_keys_pkey PRIMARY KEY (id);


--
-- Name: avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_pkey PRIMARY KEY (id);


--
-- Name: babes_date_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY babes
    ADD CONSTRAINT babes_date_key UNIQUE (date);


--
-- Name: babes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY babes
    ADD CONSTRAINT babes_pkey PRIMARY KEY (id);


--
-- Name: ban_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_pkey PRIMARY KEY (id);


--
-- Name: bazar_districts_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_code_key UNIQUE (code);


--
-- Name: bazar_districts_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_name_key UNIQUE (name);


--
-- Name: bazar_districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_pkey PRIMARY KEY (id);


--
-- Name: bets_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_pkey PRIMARY KEY (id);


--
-- Name: bets_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_options
    ADD CONSTRAINT bets_options_pkey PRIMARY KEY (id);


--
-- Name: bets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_pkey PRIMARY KEY (id);


--
-- Name: bets_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_tickets
    ADD CONSTRAINT bets_tickets_pkey PRIMARY KEY (id);


--
-- Name: bets_title_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_title_key UNIQUE (title);


--
-- Name: blogentries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_pkey PRIMARY KEY (id);


--
-- Name: cash_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cash_movements
    ADD CONSTRAINT cash_movements_pkey PRIMARY KEY (id);


--
-- Name: chatlines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY chatlines
    ADD CONSTRAINT chatlines_pkey PRIMARY KEY (id);


--
-- Name: clans_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_pkey PRIMARY KEY (id);


--
-- Name: clans_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_games
    ADD CONSTRAINT clans_games_pkey PRIMARY KEY (clan_id, game_id);


--
-- Name: clans_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_pkey PRIMARY KEY (id);


--
-- Name: clans_groups_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_name_key UNIQUE (name);


--
-- Name: clans_groups_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_pkey PRIMARY KEY (id);


--
-- Name: clans_logs_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_logs_entries
    ADD CONSTRAINT clans_logs_entries_pkey PRIMARY KEY (id);


--
-- Name: clans_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_movements
    ADD CONSTRAINT clans_movements_pkey PRIMARY KEY (id);


--
-- Name: clans_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_name_key UNIQUE (name);


--
-- Name: clans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_pkey PRIMARY KEY (id);


--
-- Name: clans_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT clans_sponsors_pkey PRIMARY KEY (id);


--
-- Name: clans_tag_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_tag_key UNIQUE (tag);


--
-- Name: columns_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_pkey PRIMARY KEY (id);


--
-- Name: columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_pkey PRIMARY KEY (id);


--
-- Name: comment_violation_opinions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: comments_valorations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_pkey PRIMARY KEY (id);


--
-- Name: comments_valorations_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_name_key UNIQUE (name);


--
-- Name: comments_valorations_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_pkey PRIMARY KEY (id);


--
-- Name: competitions_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_admins
    ADD CONSTRAINT competitions_admins_pkey PRIMARY KEY (competition_id, user_id);


--
-- Name: competitions_games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_games_maps
    ADD CONSTRAINT competitions_games_maps_pkey PRIMARY KEY (competition_id, games_map_id);


--
-- Name: competitions_logs_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_logs_entries
    ADD CONSTRAINT competitions_logs_entries_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_clans_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_clans_players
    ADD CONSTRAINT competitions_matches_clans_players_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_games_maps
    ADD CONSTRAINT competitions_matches_games_maps_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_reports
    ADD CONSTRAINT competitions_matches_reports_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_uploads
    ADD CONSTRAINT competitions_matches_uploads_pkey PRIMARY KEY (id);


--
-- Name: competitions_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_name_key UNIQUE (name);


--
-- Name: competitions_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants
    ADD CONSTRAINT competitions_participants_pkey PRIMARY KEY (id);


--
-- Name: competitions_participants_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_name_key UNIQUE (name);


--
-- Name: competitions_participants_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_pkey PRIMARY KEY (id);


--
-- Name: competitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (id);


--
-- Name: competitions_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_sponsors
    ADD CONSTRAINT competitions_sponsors_pkey PRIMARY KEY (id);


--
-- Name: competitions_supervisors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_supervisors
    ADD CONSTRAINT competitions_supervisors_pkey PRIMARY KEY (competition_id, user_id);


--
-- Name: content_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_ratings
    ADD CONSTRAINT content_ratings_pkey PRIMARY KEY (id);


--
-- Name: content_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_name_key UNIQUE (name);


--
-- Name: content_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_pkey PRIMARY KEY (id);


--
-- Name: contents_content_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_key UNIQUE (content_type_id, external_id);


--
-- Name: contents_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_locks
    ADD CONSTRAINT contents_locks_pkey PRIMARY KEY (id);


--
-- Name: contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: contents_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_pkey PRIMARY KEY (id);


--
-- Name: contents_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_pkey PRIMARY KEY (id);


--
-- Name: contents_url_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_url_key UNIQUE (url);


--
-- Name: contents_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_versions
    ADD CONSTRAINT contents_versions_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: demo_mirrors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demo_mirrors
    ADD CONSTRAINT demo_mirrors_pkey PRIMARY KEY (id);


--
-- Name: demos_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_pkey PRIMARY KEY (id);


--
-- Name: demos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_pkey PRIMARY KEY (id);


--
-- Name: downloaded_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloaded_downloads
    ADD CONSTRAINT downloaded_downloads_pkey PRIMARY KEY (id);


--
-- Name: downloadmirrors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY download_mirrors
    ADD CONSTRAINT downloadmirrors_pkey PRIMARY KEY (id);


--
-- Name: downloads_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_pkey PRIMARY KEY (id);


--
-- Name: downloads_path_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_path_key UNIQUE (file);


--
-- Name: downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_pkey PRIMARY KEY (id);


--
-- Name: dudes_date_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dudes
    ADD CONSTRAINT dudes_date_key UNIQUE (date);


--
-- Name: dudes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dudes
    ADD CONSTRAINT dudes_pkey PRIMARY KEY (id);


--
-- Name: events_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_pkey PRIMARY KEY (id);


--
-- Name: events_news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: events_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events_users
    ADD CONSTRAINT events_users_pkey PRIMARY KEY (event_id, user_id);


--
-- Name: factions_banned_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_pkey PRIMARY KEY (id);


--
-- Name: factions_building_bottom_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_bottom_key UNIQUE (building_bottom);


--
-- Name: factions_building_middle_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_middle_key UNIQUE (building_middle);


--
-- Name: factions_building_top_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_top_key UNIQUE (building_top);


--
-- Name: factions_capos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_capos
    ADD CONSTRAINT factions_capos_pkey PRIMARY KEY (id);


--
-- Name: factions_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_code_key UNIQUE (code);


--
-- Name: factions_editors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_editors
    ADD CONSTRAINT factions_editors_pkey PRIMARY KEY (id);


--
-- Name: factions_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_headers
    ADD CONSTRAINT factions_headers_pkey PRIMARY KEY (id);


--
-- Name: factions_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_links
    ADD CONSTRAINT factions_links_pkey PRIMARY KEY (id);


--
-- Name: factions_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_name_key UNIQUE (name);


--
-- Name: factions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_pkey PRIMARY KEY (id);


--
-- Name: factions_portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_portals
    ADD CONSTRAINT factions_portals_pkey PRIMARY KEY (faction_id, portal_id);


--
-- Name: faq_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_name_key UNIQUE (name);


--
-- Name: faq_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_pkey PRIMARY KEY (id);


--
-- Name: faq_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_entries
    ADD CONSTRAINT faq_entries_pkey PRIMARY KEY (id);


--
-- Name: forum_forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_pkey PRIMARY KEY (id);


--
-- Name: forum_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_pkey PRIMARY KEY (id);


--
-- Name: friends_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friends_recommendations
    ADD CONSTRAINT friends_recommendations_pkey PRIMARY KEY (id);


--
-- Name: friends_users_external_invitation_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_external_invitation_key_key UNIQUE (external_invitation_key);


--
-- Name: friends_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_pkey PRIMARY KEY (id);


--
-- Name: funthings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_pkey PRIMARY KEY (id);


--
-- Name: funthings_url_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_url_key UNIQUE (main);


--
-- Name: games_code_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_code_unique UNIQUE (code);


--
-- Name: games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_maps
    ADD CONSTRAINT games_maps_pkey PRIMARY KEY (id);


--
-- Name: games_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_modes
    ADD CONSTRAINT games_modes_pkey PRIMARY KEY (id);


--
-- Name: games_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_name_key UNIQUE (name);


--
-- Name: games_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: games_platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_platforms
    ADD CONSTRAINT games_platforms_pkey PRIMARY KEY (game_id, platform_id);


--
-- Name: games_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_versions
    ADD CONSTRAINT games_versions_pkey PRIMARY KEY (id);


--
-- Name: global_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY global_notifications
    ADD CONSTRAINT global_notifications_pkey PRIMARY KEY (id);


--
-- Name: global_vars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY global_vars
    ADD CONSTRAINT global_vars_pkey PRIMARY KEY (id);


--
-- Name: gmtv_broadcast_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gmtv_broadcast_messages
    ADD CONSTRAINT gmtv_broadcast_messages_pkey PRIMARY KEY (id);


--
-- Name: gmtv_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gmtv_channels
    ADD CONSTRAINT gmtv_channels_pkey PRIMARY KEY (id);


--
-- Name: groups_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_pkey PRIMARY KEY (id);


--
-- Name: groups_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: images_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_pkey PRIMARY KEY (id);


--
-- Name: images_path_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_path_key UNIQUE (file);


--
-- Name: images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: interviews_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_pkey PRIMARY KEY (id);


--
-- Name: interviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_pkey PRIMARY KEY (id);


--
-- Name: ip_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ip_bans
    ADD CONSTRAINT ip_bans_pkey PRIMARY KEY (id);


--
-- Name: ip_passwords_resets_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ip_passwords_resets_requests
    ADD CONSTRAINT ip_passwords_resets_requests_pkey PRIMARY KEY (id);


--
-- Name: macropolls_2007_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_pkey PRIMARY KEY (id);


--
-- Name: macropolls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY macropolls
    ADD CONSTRAINT macropolls_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: ne_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ne_references
    ADD CONSTRAINT ne_references_pkey PRIMARY KEY (id);


--
-- Name: news_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_pkey PRIMARY KEY (id);


--
-- Name: news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: outstanding_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY outstanding_entities
    ADD CONSTRAINT outstanding_users_pkey PRIMARY KEY (id);


--
-- Name: platforms_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_code_key UNIQUE (code);


--
-- Name: platforms_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);


--
-- Name: platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);


--
-- Name: polls_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_pkey PRIMARY KEY (id);


--
-- Name: polls_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_pkey PRIMARY KEY (id);


--
-- Name: polls_options_poll_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_poll_id_key UNIQUE (poll_id, name);


--
-- Name: polls_options_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_votes
    ADD CONSTRAINT polls_options_users_pkey PRIMARY KEY (id);


--
-- Name: polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: polls_title_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_title_key UNIQUE (title);


--
-- Name: portal_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portal_headers
    ADD CONSTRAINT portal_headers_pkey PRIMARY KEY (id);


--
-- Name: portal_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portal_hits
    ADD CONSTRAINT portal_hits_pkey PRIMARY KEY (id);


--
-- Name: portals_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_code_key UNIQUE (code);


--
-- Name: portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_pkey PRIMARY KEY (id);


--
-- Name: portals_skins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals_skins
    ADD CONSTRAINT portals_skins_pkey PRIMARY KEY (portal_id, skin_id);


--
-- Name: potds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_pkey PRIMARY KEY (id);


--
-- Name: products_cls_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_cls_key UNIQUE (cls);


--
-- Name: products_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_name_key UNIQUE (name);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: profile_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profile_signatures
    ADD CONSTRAINT profile_signatures_pkey PRIMARY KEY (id);


--
-- Name: publishing_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publishing_decisions
    ADD CONSTRAINT publishing_decisions_pkey PRIMARY KEY (id);


--
-- Name: publishing_personalities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publishing_personalities
    ADD CONSTRAINT publishing_personalities_pkey PRIMARY KEY (id);


--
-- Name: questions_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_pkey PRIMARY KEY (id);


--
-- Name: questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: recruitment_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_pkey PRIMARY KEY (id);


--
-- Name: refered_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_pkey PRIMARY KEY (id);


--
-- Name: reviews_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_pkey PRIMARY KEY (id);


--
-- Name: reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_info__Slony-I_gamersmafia_rowID_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_info
    ADD CONSTRAINT "schema_info__Slony-I_gamersmafia_rowID_key" UNIQUE ("_Slony-I_gamersmafia_rowID");


--
-- Name: schema_info_version_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_info
    ADD CONSTRAINT schema_info_version_key UNIQUE (version);


--
-- Name: schema_migrations_version_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);


--
-- Name: sent_emails_message_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_message_key_key UNIQUE (message_key);


--
-- Name: sent_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_pkey PRIMARY KEY (id);


--
-- Name: silenced_emails_email_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_email_key UNIQUE (email);


--
-- Name: silenced_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_pkey PRIMARY KEY (id);


--
-- Name: skin_textures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skin_textures
    ADD CONSTRAINT skin_textures_pkey PRIMARY KEY (id);


--
-- Name: skins_hid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_hid_key UNIQUE (hid);


--
-- Name: skins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_pkey PRIMARY KEY (id);


--
-- Name: slog_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slog_entries
    ADD CONSTRAINT slog_entries_pkey PRIMARY KEY (id);


--
-- Name: slog_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slog_visits
    ADD CONSTRAINT slog_visits_pkey PRIMARY KEY (user_id);


--
-- Name: sold_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sold_products
    ADD CONSTRAINT sold_products_pkey PRIMARY KEY (id);


--
-- Name: terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);


--
-- Name: textures_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY textures
    ADD CONSTRAINT textures_name_key UNIQUE (name);


--
-- Name: textures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY textures
    ADD CONSTRAINT textures_pkey PRIMARY KEY (id);


--
-- Name: tracker_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_pkey UNIQUE (id);


--
-- Name: tracker_items_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_pkey1 PRIMARY KEY (id);


--
-- Name: treated_visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);


--
-- Name: tutorials_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_pkey PRIMARY KEY (id);


--
-- Name: tutorials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_pkey PRIMARY KEY (id);


--
-- Name: user_login_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_login_changes
    ADD CONSTRAINT user_login_changes_pkey PRIMARY KEY (id);


--
-- Name: users_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_actions
    ADD CONSTRAINT users_actions_pkey PRIMARY KEY (id);


--
-- Name: users_contents_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_pkey PRIMARY KEY (id);


--
-- Name: users_emblems_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_emblems
    ADD CONSTRAINT users_emblems_pkey PRIMARY KEY (id);


--
-- Name: users_guids_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_guids
    ADD CONSTRAINT users_guids_pkey PRIMARY KEY (id);


--
-- Name: users_lastseen_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_lastseen_ips
    ADD CONSTRAINT users_lastseen_ips_pkey PRIMARY KEY (id);


--
-- Name: users_newsfeeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_newsfeeds
    ADD CONSTRAINT users_newsfeeds_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_preferences
    ADD CONSTRAINT users_preferences_pkey PRIMARY KEY (id);


--
-- Name: users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_pkey PRIMARY KEY (id);


SET search_path = stats, pg_catalog;

--
-- Name: ads_daily_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_daily
    ADD CONSTRAINT ads_daily_pkey PRIMARY KEY (id);


--
-- Name: ads_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: bandit_treatments_abtest_treatment_key; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_abtest_treatment_key UNIQUE (abtest_treatment);


--
-- Name: bandit_treatments_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_pkey PRIMARY KEY (id);


--
-- Name: bets_results_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_results
    ADD CONSTRAINT bets_results_pkey PRIMARY KEY (id);


--
-- Name: clans_daily_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_pkey PRIMARY KEY (id);


--
-- Name: general_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general
    ADD CONSTRAINT general_pkey PRIMARY KEY (created_on);


--
-- Name: pageloadtime_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageloadtime
    ADD CONSTRAINT pageloadtime_pkey PRIMARY KEY (id);


--
-- Name: pageviews_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviews_pkey PRIMARY KEY (id);


--
-- Name: portals_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_stats_pkey PRIMARY KEY (id);


--
-- Name: users_daily_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_pkey PRIMARY KEY (id);


--
-- Name: users_karma_daily_by_portal_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_karma_daily_by_portal
    ADD CONSTRAINT users_karma_daily_by_portal_pkey PRIMARY KEY (id);


SET search_path = _gamersmafia, pg_catalog;

--
-- Name: PartInd_gamersmafia_sl_log_1-node-1; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX "PartInd_gamersmafia_sl_log_1-node-1" ON sl_log_1 USING btree (log_txid) WHERE (log_origin = 1);


--
-- Name: PartInd_gamersmafia_sl_log_2-node-1; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX "PartInd_gamersmafia_sl_log_2-node-1" ON sl_log_2 USING btree (log_txid) WHERE (log_origin = 1);


--
-- Name: sl_confirm_idx1; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX sl_confirm_idx1 ON sl_confirm USING btree (con_origin, con_received, con_seqno);


--
-- Name: sl_confirm_idx2; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX sl_confirm_idx2 ON sl_confirm USING btree (con_received, con_seqno);


--
-- Name: sl_log_1_idx1; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX sl_log_1_idx1 ON sl_log_1 USING btree (log_origin, log_txid, log_actionseq);


--
-- Name: sl_log_2_idx1; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX sl_log_2_idx1 ON sl_log_2 USING btree (log_origin, log_txid, log_actionseq);


--
-- Name: sl_seqlog_idx; Type: INDEX; Schema: _gamersmafia; Owner: -; Tablespace: 
--

CREATE INDEX sl_seqlog_idx ON sl_seqlog USING btree (seql_origin, seql_ev_seqno, seql_seqid);


SET search_path = archive, pg_catalog;

--
-- Name: tracker_items_pkey; Type: INDEX; Schema: archive; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tracker_items_pkey ON tracker_items USING btree (id);


SET search_path = public, pg_catalog;

--
-- Name: anonymous_users_lastseen; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX anonymous_users_lastseen ON anonymous_users USING btree (lastseen_on);


--
-- Name: autologin_keys_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX autologin_keys_key ON autologin_keys USING btree (key);


--
-- Name: autologin_keys_lastused_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX autologin_keys_lastused_on ON autologin_keys USING btree (lastused_on);


--
-- Name: avatars_clan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_clan_id ON avatars USING btree (clan_id);


--
-- Name: avatars_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_faction_id ON avatars USING btree (faction_id);


--
-- Name: avatars_name_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX avatars_name_faction_id ON avatars USING btree (name, faction_id);


--
-- Name: avatars_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_user_id ON avatars USING btree (user_id);


--
-- Name: bets_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_approved_by_user_id ON bets USING btree (approved_by_user_id);


--
-- Name: bets_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX bets_categories_unique ON bets_categories USING btree (name, parent_id);


--
-- Name: bets_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_state ON bets USING btree (state);


--
-- Name: bets_tickets_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_tickets_user_id ON bets_tickets USING btree (user_id);


--
-- Name: bets_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_user_id ON bets USING btree (user_id);


--
-- Name: blogentries_published; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX blogentries_published ON blogentries USING btree (user_id, deleted);


--
-- Name: blogentries_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX blogentries_state ON blogentries USING btree (state);


--
-- Name: cash_movements_from; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX cash_movements_from ON cash_movements USING btree (object_id_from, object_id_from_class);


--
-- Name: cash_movements_to; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX cash_movements_to ON cash_movements USING btree (object_id_to, object_id_to_class);


--
-- Name: chatlines_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chatlines_created_on ON chatlines USING btree (created_on);


--
-- Name: clans_groups_r_users_group_user; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_groups_r_users_group_user ON clans_groups_users USING btree (clans_group_id, user_id);


--
-- Name: clans_groups_types_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_groups_types_name ON clans_groups_types USING btree (name);


--
-- Name: clans_r_games_clan_game; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_r_games_clan_game ON clans_games USING btree (clan_id, game_id);


--
-- Name: clans_r_games_clan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_r_games_clan_id ON clans_games USING btree (clan_id);


--
-- Name: clans_r_games_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_r_games_game_id ON clans_games USING btree (game_id);


--
-- Name: clans_sponsors_clan_id_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_sponsors_clan_id_name ON clans_sponsors USING btree (clan_id, name);


--
-- Name: clans_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_tag ON clans USING btree (tag);


--
-- Name: columns_appr_and_not_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_appr_and_not_deleted ON columns USING btree (approved_by_user_id, deleted);


--
-- Name: columns_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_approved_by_user_id ON columns USING btree (approved_by_user_id);


--
-- Name: columns_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX columns_categories_unique ON columns_categories USING btree (name, parent_id);


--
-- Name: columns_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_state ON columns USING btree (state);


--
-- Name: columns_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_user_id ON columns USING btree (user_id);


--
-- Name: comment_violation_opinion; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX comment_violation_opinion ON comment_violation_opinions USING btree (user_id, comment_id);


--
-- Name: comments_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_content_id ON comments USING btree (content_id);


--
-- Name: comments_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on ON comments USING btree (created_on);


--
-- Name: comments_created_on_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on_content_id ON comments USING btree (created_on, content_id);


--
-- Name: comments_created_on_date_trunc; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on_date_trunc ON comments USING btree (date_trunc('day'::text, created_on));


--
-- Name: comments_has_comments_valorations_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_has_comments_valorations_user_id ON comments USING btree (has_comments_valorations, user_id);


--
-- Name: comments_netiquette_violation; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_netiquette_violation ON comments USING btree (netiquette_violation);


--
-- Name: comments_random_v; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_random_v ON comments USING btree (random_v);


--
-- Name: comments_user_id_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_user_id_created_on ON comments USING btree (user_id, created_on);


--
-- Name: comments_valorations_comment_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX comments_valorations_comment_id_user_id ON comments_valorations USING btree (comment_id, user_id);


--
-- Name: competitions_games_maps_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX competitions_games_maps_uniq ON competitions_games_maps USING btree (competition_id, games_map_id);


--
-- Name: competitions_matches_competition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_competition_id ON competitions_matches USING btree (competition_id);


--
-- Name: competitions_matches_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_event_id ON competitions_matches USING btree (event_id);


--
-- Name: competitions_matches_participant1_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_participant1_id ON competitions_matches USING btree (participant1_id);


--
-- Name: competitions_matches_participant2_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_participant2_id ON competitions_matches USING btree (participant2_id);


--
-- Name: competitions_participants_competition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_participants_competition_id ON competitions_participants USING btree (competition_id);


--
-- Name: competitions_participants_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX competitions_participants_uniq ON competitions_participants USING btree (competition_id, participant_id, competitions_participants_type_id);


--
-- Name: competitions_supervisors_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX competitions_supervisors_uniq ON competitions_supervisors USING btree (competition_id, user_id);


--
-- Name: content_ratings_comb; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX content_ratings_comb ON content_ratings USING btree (ip, user_id, created_on);


--
-- Name: content_ratings_user_id_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX content_ratings_user_id_content_id ON content_ratings USING btree (user_id, content_id);


--
-- Name: contents_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_created_on ON contents USING btree (created_on);


--
-- Name: contents_is_public; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_is_public ON contents USING btree (is_public);


--
-- Name: contents_is_public_and_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_is_public_and_game_id ON contents USING btree (is_public, game_id);


--
-- Name: contents_locks_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_locks_uniq ON contents_locks USING btree (content_id);


--
-- Name: contents_recommendations_content_id_sender_user_id_receiver_use; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_recommendations_content_id_sender_user_id_receiver_use ON contents_recommendations USING btree (content_id, sender_user_id, receiver_user_id);


--
-- Name: contents_recommendations_receiver_user_id_marked_as_bad; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_recommendations_receiver_user_id_marked_as_bad ON contents_recommendations USING btree (receiver_user_id, marked_as_bad);


--
-- Name: contents_recommendations_seen_on_content_id_receiver_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_recommendations_seen_on_content_id_receiver_user_id ON contents_recommendations USING btree (content_id, receiver_user_id);


--
-- Name: contents_recommendations_sender_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_recommendations_sender_user_id ON contents_recommendations USING btree (sender_user_id);


--
-- Name: contents_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_state ON contents USING btree (state);


--
-- Name: contents_state_clan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_state_clan_id ON contents USING btree (state, clan_id);


--
-- Name: contents_terms_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_terms_content_id ON contents_terms USING btree (content_id);


--
-- Name: contents_terms_term_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_terms_term_id ON contents_terms USING btree (term_id);


--
-- Name: contents_terms_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_terms_uniq ON contents_terms USING btree (content_id, term_id);


--
-- Name: contents_user_id_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_user_id_state ON contents USING btree (user_id, state);


--
-- Name: demos_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_approved_by_user_id ON demos USING btree (approved_by_user_id);


--
-- Name: demos_approved_by_user_id_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_approved_by_user_id_deleted ON demos USING btree (approved_by_user_id, deleted);


--
-- Name: demos_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_categories_unique ON demos_categories USING btree (name, parent_id);


--
-- Name: demos_common; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_common ON demos USING btree (created_on, approved_by_user_id, deleted, user_id, demos_category_id);


--
-- Name: demos_file; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_file ON demos USING btree (file);


--
-- Name: demos_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_hash_md5 ON demos USING btree (file_hash_md5);


--
-- Name: demos_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_state ON demos USING btree (state);


--
-- Name: demos_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_user_id ON demos USING btree (user_id);


--
-- Name: downloads_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_approved_by_user_id ON downloads USING btree (approved_by_user_id);


--
-- Name: downloads_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX downloads_categories_unique ON downloads_categories USING btree (name, parent_id);


--
-- Name: downloads_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_hash_md5 ON downloads USING btree (file_hash_md5);


--
-- Name: downloads_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_state ON downloads USING btree (state);


--
-- Name: downloads_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_user_id ON downloads USING btree (user_id);


--
-- Name: events_appr_and_not_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_appr_and_not_deleted ON events USING btree (approved_by_user_id, deleted);


--
-- Name: events_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_approved_by_user_id ON events USING btree (approved_by_user_id);


--
-- Name: events_news_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_approved_by_user_id ON coverages USING btree (approved_by_user_id);


--
-- Name: events_news_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_state ON coverages USING btree (state);


--
-- Name: events_news_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_user_id ON coverages USING btree (user_id);


--
-- Name: events_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_state ON events USING btree (state);


--
-- Name: events_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_user_id ON events USING btree (user_id);


--
-- Name: factions_banned_users_fu; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_banned_users_fu ON factions_banned_users USING btree (faction_id, user_id);


--
-- Name: factions_capos_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_capos_uniq ON factions_capos USING btree (faction_id, user_id);


--
-- Name: factions_editors_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_editors_uniq ON factions_editors USING btree (faction_id, user_id, content_type_id);


--
-- Name: factions_headers_lasttime_used_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX factions_headers_lasttime_used_on ON factions_headers USING btree (lasttime_used_on);


--
-- Name: factions_headers_names_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_headers_names_faction_id ON factions_headers USING btree (faction_id, name);


--
-- Name: factions_links_names_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_links_names_faction_id ON factions_links USING btree (faction_id, name);


--
-- Name: forum_forums_code_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX forum_forums_code_name_parent_id ON topics_categories USING btree (code, name, parent_id);


--
-- Name: forum_topics_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX forum_topics_state ON topics USING btree (state);


--
-- Name: forum_topics_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX forum_topics_user_id ON topics USING btree (user_id);


--
-- Name: friends_recommendations_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX friends_recommendations_uniq ON friends_recommendations USING btree (user_id, recommended_user_id);


--
-- Name: friends_recommendations_user_id_undecided; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX friends_recommendations_user_id_undecided ON friends_recommendations USING btree (user_id, added_as_friend);


--
-- Name: friends_users_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX friends_users_uniq ON friendships USING btree (sender_user_id, receiver_user_id);


--
-- Name: funthings_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX funthings_state ON funthings USING btree (state);


--
-- Name: funthings_title_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX funthings_title_uniq ON funthings USING btree (title);


--
-- Name: games_maps_name_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_maps_name_game_id ON games_maps USING btree (name, game_id);


--
-- Name: games_modes_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_modes_uniq ON games_modes USING btree (name, game_id);


--
-- Name: games_users_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX games_users_game_id ON games_users USING btree (game_id);


--
-- Name: games_users_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_users_uniq ON games_users USING btree (user_id, game_id);


--
-- Name: games_users_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX games_users_user_id ON games_users USING btree (user_id);


--
-- Name: games_versions_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_versions_uniq ON games_versions USING btree (version, game_id);


--
-- Name: images_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_approved_by_user_id ON images USING btree (approved_by_user_id);


--
-- Name: images_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX images_categories_unique ON images_categories USING btree (name, parent_id);


--
-- Name: images_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_hash_md5 ON images USING btree (file_hash_md5);


--
-- Name: images_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_state ON images USING btree (state);


--
-- Name: images_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_user_id ON images USING btree (user_id);


--
-- Name: interviews_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_approved_by_user_id ON interviews USING btree (approved_by_user_id);


--
-- Name: interviews_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX interviews_categories_unique ON interviews_categories USING btree (name, parent_id);


--
-- Name: interviews_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_state ON interviews USING btree (state);


--
-- Name: interviews_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_user_id ON interviews USING btree (user_id);


--
-- Name: ip_passwords_resets_requests_ip_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ip_passwords_resets_requests_ip_created_on ON ip_passwords_resets_requests USING btree (ip, created_on);


--
-- Name: messages_user_id_is_read; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_user_id_is_read ON messages USING btree (user_id_to) WHERE (is_read IS FALSE);


--
-- Name: ne_references_entity; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ne_references_entity ON ne_references USING btree (entity_class, entity_id);


--
-- Name: ne_references_referencer; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ne_references_referencer ON ne_references USING btree (referencer_class, referencer_id);


--
-- Name: ne_references_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ne_references_uniq ON ne_references USING btree (entity_class, entity_id, referencer_class, referencer_id);


--
-- Name: news_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_approved_by_user_id ON news USING btree (approved_by_user_id);


--
-- Name: news_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX news_categories_unique ON news_categories USING btree (name, parent_id);


--
-- Name: news_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_state ON news USING btree (state);


--
-- Name: news_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_user_id ON news USING btree (user_id);


--
-- Name: outstanding_entities_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX outstanding_entities_uniq ON outstanding_entities USING btree (type, portal_id, active_on);


--
-- Name: platforms_users_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX platforms_users_platform_id ON platforms_users USING btree (platform_id);


--
-- Name: platforms_users_platform_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX platforms_users_platform_id_user_id ON platforms_users USING btree (user_id, platform_id);


--
-- Name: platforms_users_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX platforms_users_user_id ON platforms_users USING btree (user_id);


--
-- Name: polls_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_approved_by_user_id ON polls USING btree (approved_by_user_id);


--
-- Name: polls_categories_code_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX polls_categories_code_parent_id ON polls_categories USING btree (code, parent_id);


--
-- Name: polls_categories_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX polls_categories_name_parent_id ON polls_categories USING btree (name, parent_id);


--
-- Name: polls_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_state ON polls USING btree (state);


--
-- Name: polls_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_user_id ON polls USING btree (user_id);


--
-- Name: portal_hits_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portal_hits_uniq ON portal_hits USING btree (portal_id, date);


--
-- Name: portals_name_code_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portals_name_code_type ON portals USING btree (name, code, type);


--
-- Name: potds_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX potds_uniq ON potds USING btree (date, portal_id, images_category_id);


--
-- Name: profile_signatures_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX profile_signatures_user_id ON profile_signatures USING btree (user_id);


--
-- Name: profile_signatures_user_id_signer_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX profile_signatures_user_id_signer_user_id ON profile_signatures USING btree (user_id, signer_user_id);


--
-- Name: publishing_decisions_user_id_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX publishing_decisions_user_id_content_id ON publishing_decisions USING btree (user_id, content_id);


--
-- Name: publishing_personalities_user_id_content_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX publishing_personalities_user_id_content_type_id ON publishing_personalities USING btree (user_id, content_type_id);


--
-- Name: questions_categories_code_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX questions_categories_code_name_parent_id ON questions_categories USING btree (code, name, parent_id);


--
-- Name: questions_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_state ON questions USING btree (state);


--
-- Name: questions_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_user_id ON questions USING btree (user_id);


--
-- Name: refered_hits_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX refered_hits_user_id ON refered_hits USING btree (user_id);


--
-- Name: reviews_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_approved_by_user_id ON reviews USING btree (approved_by_user_id);


--
-- Name: reviews_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX reviews_categories_unique ON reviews_categories USING btree (name, parent_id);


--
-- Name: reviews_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_state ON reviews USING btree (state);


--
-- Name: reviews_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_user_id ON reviews USING btree (user_id);


--
-- Name: sent_emails_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sent_emails_created_on ON sent_emails USING btree (created_on);


--
-- Name: sent_emails_gnotif; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sent_emails_gnotif ON sent_emails USING btree (global_notification_id);


--
-- Name: silenced_emails_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX silenced_emails_lower ON silenced_emails USING btree (lower((email)::text));


--
-- Name: slog_entries_completed_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slog_entries_completed_on ON slog_entries USING btree (completed_on);


--
-- Name: slog_entries_headline; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slog_entries_headline ON slog_entries USING btree (headline);


--
-- Name: slog_entries_scope; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slog_entries_scope ON slog_entries USING btree (scope);


--
-- Name: slog_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slog_type_id ON slog_entries USING btree (type_id);


--
-- Name: terms_name_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_name_uniq ON terms USING btree (game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, name);


--
-- Name: terms_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_parent_id ON terms USING btree (parent_id);


--
-- Name: terms_root_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_root_id ON terms USING btree (root_id);


--
-- Name: terms_root_id_parent_id_taxonomy; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_root_id_parent_id_taxonomy ON terms USING btree (root_id, parent_id, taxonomy);


--
-- Name: terms_slug_toplevel; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX terms_slug_toplevel ON terms USING btree (slug) WHERE (parent_id IS NULL);


--
-- Name: terms_slug_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_slug_uniq ON terms USING btree (game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, slug);


--
-- Name: tracker_items_content_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tracker_items_content_id_user_id ON tracker_items USING btree (content_id, user_id);


--
-- Name: tracker_items_full; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tracker_items_full ON tracker_items USING btree (content_id, user_id, lastseen_on, is_tracked);


--
-- Name: tracker_items_user_id_is_tracked; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tracker_items_user_id_is_tracked ON tracker_items USING btree (user_id, is_tracked) WHERE (is_tracked = true);


--
-- Name: treated_visitors_multi; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX treated_visitors_multi ON treated_visitors USING btree (ab_test_id, visitor_id, treatment);


--
-- Name: treated_visitors_per_test; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX treated_visitors_per_test ON treated_visitors USING btree (ab_test_id, visitor_id);


--
-- Name: tutorials_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_approved_by_user_id ON tutorials USING btree (approved_by_user_id);


--
-- Name: tutorials_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tutorials_categories_unique ON tutorials_categories USING btree (name, parent_id);


--
-- Name: tutorials_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_state ON tutorials USING btree (state);


--
-- Name: tutorials_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_user_id ON tutorials USING btree (user_id);


--
-- Name: users_actions_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_actions_created_on ON users_actions USING btree (created_on);


--
-- Name: users_cache_remaning; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_cache_remaning ON users USING btree (cache_remaining_rating_slots) WHERE (cache_remaining_rating_slots IS NOT NULL);


--
-- Name: users_comments_sig; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_comments_sig ON users USING btree (comments_sig);


--
-- Name: users_contents_tags_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_contents_tags_content_id ON users_contents_tags USING btree (content_id);


--
-- Name: users_contents_tags_term_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_contents_tags_term_id ON users_contents_tags USING btree (term_id);


--
-- Name: users_contents_tags_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_contents_tags_user_id ON users_contents_tags USING btree (user_id);


--
-- Name: users_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_email_id ON users USING btree (email, id);


--
-- Name: users_emblems_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_emblems_created_on ON users_emblems USING btree (created_on);


--
-- Name: users_emblems_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_emblems_user_id ON users_emblems USING btree (user_id);


--
-- Name: users_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_faction_id ON users USING btree (faction_id);


--
-- Name: users_guids_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_guids_uniq ON users_guids USING btree (guid, game_id);


--
-- Name: users_lastseen; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lastseen ON users USING btree (lastseen_on);


--
-- Name: users_login_ne_unfriendly; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_login_ne_unfriendly ON users USING btree (login_is_ne_unfriendly);


--
-- Name: users_lower_all; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lower_all ON users USING btree (lower((login)::text), lower((email)::text), lower((firstname)::text), lower((lastname)::text), ipaddr);


--
-- Name: users_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lower_login ON users USING btree (lower((login)::text));


--
-- Name: users_newsfeeds_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_newsfeeds_created_on ON users_newsfeeds USING btree (created_on);


--
-- Name: users_newsfeeds_created_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_newsfeeds_created_on_user_id ON users_newsfeeds USING btree (created_on, user_id);


--
-- Name: users_preferences_user_id_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_preferences_user_id_name ON users_preferences USING btree (user_id, name);


--
-- Name: users_random_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_random_id ON users USING btree (random_id);


--
-- Name: users_roles_role; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_role ON users_roles USING btree (role);


--
-- Name: users_roles_role_role_data; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_role_role_data ON users_roles USING btree (role, role_data);


--
-- Name: users_roles_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_roles_uniq ON users_roles USING btree (user_id, role, role_data);


--
-- Name: users_roles_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_user_id ON users_roles USING btree (user_id);


--
-- Name: users_secret; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_secret ON users USING btree (secret);


--
-- Name: users_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_state ON users USING btree (state);


--
-- Name: users_uniq_lower_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_uniq_lower_email ON users USING btree (lower((email)::text));


--
-- Name: users_uniq_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_uniq_lower_login ON users USING btree (lower((login)::text));


--
-- Name: users_validkey; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_validkey ON users USING btree (validkey);


SET search_path = stats, pg_catalog;

--
-- Name: bandit_treatments_abtest_treatment; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX bandit_treatments_abtest_treatment ON bandit_treatments USING btree (abtest_treatment);


--
-- Name: clans_daily_stats_clan_id_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX clans_daily_stats_clan_id_created_on ON clans_daily_stats USING btree (clan_id, created_on);


--
-- Name: dates_date; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX dates_date ON dates USING btree (date);


--
-- Name: pageloadtime_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageloadtime_created_on ON pageloadtime USING btree (created_on);


--
-- Name: pageviews_abtest_treatmentnotnull; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_abtest_treatmentnotnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NOT NULL);


--
-- Name: pageviews_abtest_treatmentnull; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_abtest_treatmentnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NULL);


--
-- Name: pageviews_created_on_abtest_treatment; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_created_on_abtest_treatment ON pageviews USING btree (created_on, abtest_treatment);


--
-- Name: pageviews_id_visitor_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_id_visitor_id ON pageviews USING btree (visitor_id, id);


--
-- Name: pageviews_portal_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_portal_id ON pageviews USING btree (portal_id);


--
-- Name: pageviews_visitor_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_visitor_id ON pageviews USING btree (visitor_id);


--
-- Name: pageviews_visitor_id_and_tstamps; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_visitor_id_and_tstamps ON pageviews USING btree (visitor_id, created_on);


--
-- Name: portals_stats_portal_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX portals_stats_portal_id ON portals USING btree (portal_id);


--
-- Name: portals_stats_uniq; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portals_stats_uniq ON portals USING btree (created_on, portal_id);


--
-- Name: users_daily_stats_user_id_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX users_daily_stats_user_id_created_on ON users_daily_stats USING btree (user_id, created_on);


--
-- Name: users_karma_daily_by_portal_uniq; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_karma_daily_by_portal_uniq ON users_karma_daily_by_portal USING btree (user_id, portal_id, created_on);


SET search_path = _gamersmafia, pg_catalog;

--
-- Name: li_origin-no_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_listen
    ADD CONSTRAINT "li_origin-no_id-ref" FOREIGN KEY (li_origin) REFERENCES sl_node(no_id);


--
-- Name: pa_client-no_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_path
    ADD CONSTRAINT "pa_client-no_id-ref" FOREIGN KEY (pa_client) REFERENCES sl_node(no_id);


--
-- Name: pa_server-no_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_path
    ADD CONSTRAINT "pa_server-no_id-ref" FOREIGN KEY (pa_server) REFERENCES sl_node(no_id);


--
-- Name: seq_set-set_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_sequence
    ADD CONSTRAINT "seq_set-set_id-ref" FOREIGN KEY (seq_set) REFERENCES sl_set(set_id);


--
-- Name: set_origin-no_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_set
    ADD CONSTRAINT "set_origin-no_id-ref" FOREIGN KEY (set_origin) REFERENCES sl_node(no_id);


--
-- Name: sl_listen-sl_path-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_listen
    ADD CONSTRAINT "sl_listen-sl_path-ref" FOREIGN KEY (li_provider, li_receiver) REFERENCES sl_path(pa_server, pa_client);


--
-- Name: sl_subscribe-sl_path-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_subscribe
    ADD CONSTRAINT "sl_subscribe-sl_path-ref" FOREIGN KEY (sub_provider, sub_receiver) REFERENCES sl_path(pa_server, pa_client);


--
-- Name: ssy_origin-no_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_setsync
    ADD CONSTRAINT "ssy_origin-no_id-ref" FOREIGN KEY (ssy_origin) REFERENCES sl_node(no_id);


--
-- Name: ssy_setid-set_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_setsync
    ADD CONSTRAINT "ssy_setid-set_id-ref" FOREIGN KEY (ssy_setid) REFERENCES sl_set(set_id);


--
-- Name: sub_set-set_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_subscribe
    ADD CONSTRAINT "sub_set-set_id-ref" FOREIGN KEY (sub_set) REFERENCES sl_set(set_id);


--
-- Name: tab_set-set_id-ref; Type: FK CONSTRAINT; Schema: _gamersmafia; Owner: -
--

ALTER TABLE ONLY sl_table
    ADD CONSTRAINT "tab_set-set_id-ref" FOREIGN KEY (tab_set) REFERENCES sl_set(set_id);


SET search_path = public, pg_catalog;

--
-- Name: bets_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);


--
-- Name: bets_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: bets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: bets_winning_bets_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_winning_bets_option_id_fkey FOREIGN KEY (winning_bets_option_id) REFERENCES bets_options(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: blogentries_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: blogentries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: clans_creator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: columns_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: comment_violation_opinions_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES comments(id);


--
-- Name: comment_violation_opinions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: competitions_matches_participant1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant1_id_fkey FOREIGN KEY (participant1_id) REFERENCES competitions_participants(id);


--
-- Name: competitions_matches_participant2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant2_id_fkey FOREIGN KEY (participant2_id) REFERENCES competitions_participants(id);


--
-- Name: contents_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: contents_content_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_fkey FOREIGN KEY (content_type_id) REFERENCES content_types(id) MATCH FULL;


--
-- Name: contents_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: contents_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL;


--
-- Name: contents_terms_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: contents_terms_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: contents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: coverages_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT coverages_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: demos_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);


--
-- Name: demos_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: demos_games_map_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_map_id_fkey FOREIGN KEY (games_map_id) REFERENCES games_maps(id) MATCH FULL;


--
-- Name: demos_games_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_mode_id_fkey FOREIGN KEY (games_mode_id) REFERENCES games_modes(id) MATCH FULL;


--
-- Name: demos_games_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_version_id_fkey FOREIGN KEY (games_version_id) REFERENCES games_versions(id) MATCH FULL;


--
-- Name: demos_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: demos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: downloads_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: downloads_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: events_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: events_news_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_news_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: events_news_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES events(id) MATCH FULL;


--
-- Name: events_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: forum_topics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: funthings_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: funthings_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: funthings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: groups_messages_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES groups_messages(id) MATCH FULL;


--
-- Name: groups_messages_root_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_root_id_fkey FOREIGN KEY (root_id) REFERENCES groups_messages(id) MATCH FULL;


--
-- Name: groups_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: images_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: images_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: interviews_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: macropolls_2007_1_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: macropolls_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macropolls
    ADD CONSTRAINT macropolls_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: news_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: news_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: platforms_users_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY platforms_users
    ADD CONSTRAINT platforms_users_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: platforms_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY platforms_users
    ADD CONSTRAINT platforms_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: polls_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: polls_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: potds_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_image_id_fkey FOREIGN KEY (image_id) REFERENCES images(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: potds_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: questions_accepted_answer_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_accepted_answer_comment_id_fkey FOREIGN KEY (accepted_answer_comment_id) REFERENCES comments(id);


--
-- Name: questions_answer_selected_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_answer_selected_by_user_id_fkey FOREIGN KEY (answer_selected_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: questions_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: questions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: recruitment_ads_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: recruitment_ads_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id) MATCH FULL;


--
-- Name: recruitment_ads_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: recruitment_ads_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: recruitment_ads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: refered_hits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: reviews_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: terms_bazar_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_bazar_district_id_fkey FOREIGN KEY (bazar_district_id) REFERENCES bazar_districts(id) MATCH FULL;


--
-- Name: terms_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: terms_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: terms_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES contents(id);


--
-- Name: terms_parent_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_parent_term_id_fkey FOREIGN KEY (parent_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: terms_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL;


--
-- Name: terms_root_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_root_id_fkey FOREIGN KEY (root_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: topics_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: topics_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: tutorials_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: users_avatar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_avatar_id_fkey FOREIGN KEY (avatar_id) REFERENCES avatars(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: users_comments_valorations_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_comments_valorations_type_id_fkey FOREIGN KEY (comments_valorations_type_id) REFERENCES comments_valorations_types(id);


--
-- Name: users_contents_tags_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id);


--
-- Name: users_contents_tags_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id);


--
-- Name: users_contents_tags_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: users_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: users_last_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_clan_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey1 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_clan_id_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey2 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey1 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey2 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_referer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_referer_user_id_fkey FOREIGN KEY (referer_user_id) REFERENCES users(id) MATCH FULL;


SET search_path = stats, pg_catalog;

--
-- Name: clans_daily_stats_clan_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES public.clans(id) MATCH FULL;


--
-- Name: users_daily_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;


--
-- PostgreSQL database dump complete
--

