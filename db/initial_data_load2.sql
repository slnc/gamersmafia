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
-- Name: games_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('games', 'id'), 59, true);


--
-- Data for Name: games; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY games (id, name, code) FROM stdin;
13	Unreal Tournament	ut
14	Unreal Tournament 2003	ut2003
15	Doom 3	d3
17	Battlefield 1942	bf1942
10	Unreal Tournament 2004	ut2004
18	Call of Duty	cod
16	Quake 3 Arena	q3a
19	Neverwinter Nights	nwn
20	Soldier of Fortune 2	sof2
21	America's Army	aa
22	Counter-Strike	cs
24	World of Warcraft	wow
25	Medal of Honor	moh
26	Starcraft	sc
27	Counter-Strike: Source	css
28	Half-Life	hl
29	Half-Life 2	hl2
30	Unreal	u
31	Quake	q
32	Quake 2	q2
33	Painkiller	pk
34	FarCry	fc
35	FIFA	fifa
36	Wolfenstein: Enemy Territory	et
37	Return To Castle Wolfenstein	rtcw
38	Pro Evolution Soccer 4	pes4
23	Warcraft III	wc3
39	Rome Total War	rome
40	Halo 2	halo2
41	Halo	halo
42	Joint Operations	jo
43	Praetorians	pra
44	Age of Empires	aoe
45	XIII	xiii
46	NHL	nhl
47	Age of Myth	aom
48	Need For Speed	nfs
49	Command & Conquer	c&c
50	Raven Shield	rs
51	Tribes 2	t2
12	Ragnarok Online	ro
52	Warhammer 40k: Dawn of War	dow
53	Guildwars	gw
54	Battlefield 2	Bf 2
55	Dance Dance Revolutions	ddr
56	Quake 4	q4
57	Unreal Tournament 2007	ut2007
58	Call of Duty 2	cod2
59	Swat 4	s4
\.


--
-- Name: games_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_code_unique UNIQUE (code);


--
-- Name: games_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_name_key UNIQUE (name);


--
-- Name: games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--



insert into content_types(name) VALUES('tutorial');
insert into content_types(name) VALUES('interview');
insert into content_types(name) VALUES('column');
insert into content_types(name) VALUES('review');
insert into content_types(name) VALUES('funthing');
