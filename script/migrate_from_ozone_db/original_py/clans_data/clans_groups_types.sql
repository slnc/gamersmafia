--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: clans_groups_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE clans_groups_types (
    id serial NOT NULL,
    name character varying NOT NULL
);


--
-- Name: clans_groups_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('clans_groups_types', 'id'), 2, true);


--
-- Data for Name: clans_groups_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clans_groups_types (id, name) FROM stdin;
1	clanleaders
2	members
\.


--
-- Name: clans_groups_types_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_name_key UNIQUE (name);


--
-- Name: clans_groups_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_pkey PRIMARY KEY (id);


--
-- Name: clans_groups_types_name; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX clans_groups_types_name ON clans_groups_types USING btree (name);


--
-- PostgreSQL database dump complete
--

