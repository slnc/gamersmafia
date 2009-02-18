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
-- Name: clans_sponsors; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE clans_sponsors (
    id serial NOT NULL,
    name character varying NOT NULL,
    clan_id integer NOT NULL,
    url character varying,
    image character varying
);


--
-- Name: clans_sponsors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('clans_sponsors', 'id'), 422, true);


--
-- Data for Name: clans_sponsors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clans_sponsors (id, name, clan_id, url, image) FROM stdin;
151	Gamersmafia	370	Gamersmafia.com	\N
94	XyOn Servers	243	www.xyon-servers.com	\N
44	4 America's Army	93	www.4AmericasArmy.com	\N
16	AMD	69	http://www.amd.com	\N
95	Clan .spain	253	www.clan-spain.ya.st	\N
19	4 America's Army	19	http://www.4AmericasArmy.com	\N
20	OnePlayNet	74	http://www.oneplaynet.com	\N
21	Premium Networks	71	www.PremiumNetworks.org	\N
22	Nova-Design	71	www.nova-design.net	\N
34	Ciberaguilas	109	www.ciberaguilas.com	\N
40	Ciber Aguilas 	108	www.CiberAguilas.com	\N
78	InetCoffee	202	www.inetcoffee.net	\N
98	Sposor de prueba	198	www.clanaaa.es.vg	\N
85	NO SPONSOR	232	www.media-vida.net	\N
129	AMD	298	www.amd.com	\N
91	pastiseria Caty	55	\N	\N
130	Nvidia	298	www.nvidia.com	\N
131	4 America's Army	301	www.4AmericasArmy.com	\N
145	no sponsor	363	www.areazero.net	\N
143	XyOn-Servers	330	www.xyon-servers.com	\N
137	Ligas Lince	301	www.ligas-lince.com	\N
134	NeTGame-S	302	www.NetGame-s.com	\N
155	Demente	264	www.demente.cjb.net	\N
135	newlightsystems.com	305	newlightsystems.com/index.php	\N
152	DistroBit	370	DistroBit.com	\N
153	Clan 145	374	www.clan145.com	\N
118	servidores.com	111	gamers.servidores.com/	\N
150	Platina Esports	343	\N	\N
263	eLinks.tk	636	eLinks.tk/	\N
192	online-servers	470	www.Online-Servers.org	\N
217	Remhost	539	www.remhost.com	\N
223	Modut	544	modut.gamersmafia.com	\N
224	Extreme killers	552	\N	\N
248	FasteLinks	588	www.fastelinks.tk	\N
287	Andaina.org	725	www.Andaina.org	\N
336	Archivos Para todo I Grati$	859	www.archivospc.com	\N
314	MecaHost	804	www.mecahost.com/	\N
376	Net Gaming	1012	club.telepolis.com/ngsevilla/	\N
388	4unrealers	1053	www.4unrealers.com	\N
405	Sparco	1096	\N	\N
202	L.GamerZ	521	\N	homehttpdwebsitesgamersmafiastorageclans521sponsors202.jpg
216	Informatica EspaÃ±ola	536	www.infores.es	homehttpdwebsitesgamersmafiastorageclans536sponsors216.jpg
251	ReMhost.net	541	www.ReMhost.net	homehttpdwebsitesgamersmafiastorageclans541sponsors251.jpg
4	Sheeva	3	http://www.sheeva.be/	homehttpdwebsitesgamersmafiastorageclans3sponsors4.gif
6	HispaHost.Org	3	http://www.hispahost.org/	homehttpdwebsitesgamersmafiastorageclans3sponsors6.gif
8	Gamersmafia	5	gamersmafia.com	homehttpdwebsitesgamersmafiastorageclans5sponsors8.png
3	4 America's Army	14	www.4AmericasArmy.com	homehttpdwebsitesgamersmafiastorageclans14sponsors3.gif
89	Clanbase	236	www.clanbase.com	homehttpdwebsitesgamersmafiastorageclans236sponsors89.gif
213	[JP]	295	\N	homehttpdwebsitesgamersmafiastorageclans295sponsors213.jpg
174	Spanish-Arena	381	www.spanish-arena.com	homehttpdwebsitesgamersmafiastorageclans381sponsors174.jpg
175	DowHispano	381	www.dowhispano.com	homehttpdwebsitesgamersmafiastorageclans381sponsors175.jpg
9	BattlefieldSpain	5	http://battlefieldspain.com	homehttpdwebsitesgamersmafiastorageclans5sponsors9.jpg
12	DANONE	13	http://www.danone.es/indexnew.html	homehttpdwebsitesgamersmafiastorageclans13sponsors12.jpg
71	Gamers Mafia Staff	17	www.GamersMafia.com	homehttpdwebsitesgamersmafiastorageclans17sponsors71.gif
7	WFGaming	21	http://www.wfgaming.com/	homehttpdwebsitesgamersmafiastorageclans21sponsors7.jpg
173	CLAN BASE	29	www.clanbase.com/news.php	homehttpdwebsitesgamersmafiastorageclans29sponsors173.gif
154	#2v2.EU	43	www.EU-Gaming.com	homehttpdwebsitesgamersmafiastorageclans43sponsors154.jpg
169	u2d-Clan	43	www.u2dclan.tk	homehttpdwebsitesgamersmafiastorageclans43sponsors169.jpg
15	Looking for Sponsors	46	\N	homehttpdwebsitesgamersmafiastorageclans46sponsors15.jpg
23	Wad-Net	80	www.wad-net.com	homehttpdwebsitesgamersmafiastorageclans80sponsors23.gif
24	Jump Ordenadores	80	www.jump.es	homehttpdwebsitesgamersmafiastorageclans80sponsors24.jpg
29	#Play-Net	98	www.play-net.net	homehttpdwebsitesgamersmafiastorageclans98sponsors29.jpg
256	4dow	136	4dow.net	homehttpdwebsitesgamersmafiastorageclans136sponsors256.jpg
96	SPANISH-ARENA.COM	136	www.spanish-arena.com	homehttpdwebsitesgamersmafiastorageclans136sponsors96.jpg
68	4 America's Army	137	www.4AmericasArmy.com	homehttpdwebsitesgamersmafiastorageclans137sponsors68.gif
70	Gamers Mafia	137	www.GamersMafia.com	homehttpdwebsitesgamersmafiastorageclans137sponsors70.gif
62	AMD	139	AMD.com	homehttpdwebsitesgamersmafiastorageclans139sponsors62.jpg
64	Google	139	www.Google.es/	homehttpdwebsitesgamersmafiastorageclans139sponsors64.jpg
158	Imaginet	167	www.imaginet-coslada.com	homehttpdwebsitesgamersmafiastorageclans167sponsors158.jpg
66	Imaginet	170	www.imaginet-coslada.com	homehttpdwebsitesgamersmafiastorageclans170sponsors66.jpg
92	Wolfspain	170	www.wolfspain.net	homehttpdwebsitesgamersmafiastorageclans170sponsors92.jpg
73	Quaker Religion	191	www.QuakeReligion.com	homehttpdwebsitesgamersmafiastorageclans191sponsors73.gif
74	Gamers Mafia	191	www.GamersMafia.com	homehttpdwebsitesgamersmafiastorageclans191sponsors74.gif
188	Clanbase	199	www.clanbase.com/news.php	homehttpdwebsitesgamersmafiastorageclans199sponsors188.jpg
193	Nxhosting	199	www.nxhosting.co.uk	homehttpdwebsitesgamersmafiastorageclans199sponsors193.jpg
87	spaniXservers	222	www.spaniXservers.com	homehttpdwebsitesgamersmafiastorageclans222sponsors87.jpg
90	Junta de AndalucÃ­a	236	www.juntadeandalucia.es/	homehttpdwebsitesgamersmafiastorageclans236sponsors90.gif
324	4 Warcraft	294	www.4warcraft.com	homehttpdwebsitesgamersmafiastorageclans294sponsors324.jpg
295	DeathONE home site	304	dh1.gamersmafia.com	homehttpdwebsitesgamersmafiastorageclans304sponsors295.jpg
166	Cslimite.net	304	www.cslimite.net/portal	homehttpdwebsitesgamersmafiastorageclans304sponsors166.jpg
168	~(DMT)~CLAN	314	www.dmt.wol.bz	homehttpdwebsitesgamersmafiastorageclans314sponsors168.gif
230	4U	329	4unrealers.com	homehttpdwebsitesgamersmafiastorageclans329sponsors230.gif
231	Arenanet	329	www.arena.net/news/index.html	homehttpdwebsitesgamersmafiastorageclans329sponsors231.gif
162	4u	367	4unrealers.com	homehttpdwebsitesgamersmafiastorageclans367sponsors162.jpg
262	CLANNATION	402	www.clannation.de	homehttpdwebsitesgamersmafiastorageclans402sponsors262.jpg
178	Google	403	www.google.es	homehttpdwebsitesgamersmafiastorageclans403sponsors178.jpg
181	Mundo Wayun	421	wayunworld.webcindario.com	homehttpdwebsitesgamersmafiastorageclans421sponsors181.gif
183	Sanakas	422	camaleon99.freefronthost.com	homehttpdwebsitesgamersmafiastorageclans422sponsors183.gif
187	Sanakas	437	www.sanakas.tk	homehttpdwebsitesgamersmafiastorageclans437sponsors187.gif
194	GOOGLE	476	WWW.GOOGLE.ES	homehttpdwebsitesgamersmafiastorageclans476sponsors194.jpg
198	WaD-Net	477	www.wad-net.com	homehttpdwebsitesgamersmafiastorageclans477sponsors198.gif
222	4coders	477	www.4coders.net	homehttpdwebsitesgamersmafiastorageclans477sponsors222.png
207	Digital System Design	478	www.dsdcorporation.com	homehttpdwebsitesgamersmafiastorageclans478sponsors207.jpg
195	CLAN BASE	484	www.clanbase.com/news.php	homehttpdwebsitesgamersmafiastorageclans484sponsors195.gif
203	google	507	www.google.es	homehttpdwebsitesgamersmafiastorageclans507sponsors203.jpg
309	fredulic fotolog	510	fotolog.net/fredulic	homehttpdwebsitesgamersmafiastorageclans510sponsors309.gif
310	issuzu fotolog	510	fotolog.net/issuzu	homehttpdwebsitesgamersmafiastorageclans510sponsors310.gif
200	Google EspaÃ±a	518	www.google.es/	homehttpdwebsitesgamersmafiastorageclans518sponsors200.jpg
201	MSN EspaÃ±a	518	www.msn.es/	homehttpdwebsitesgamersmafiastorageclans518sponsors201.jpg
402	mpasoft	525	www.mpasoft.com	homehttpdwebsitesgamersmafiastorageclans525sponsors402.png
215	Dowhispano	536	www.dowhispano.com	homehttpdwebsitesgamersmafiastorageclans536sponsors215.jpg
252	Andaina.org	541	www.andaina.org	homehttpdwebsitesgamersmafiastorageclans541sponsors252.jpg
220	Se busca	542	sebusca.com	homehttpdwebsitesgamersmafiastorageclans542sponsors220.jpg
221	Se busca	545	sebusca.com	homehttpdwebsitesgamersmafiastorageclans545sponsors221.jpg
400	ultimate	559	ulti.gamersmafia.com/	homehttpdwebsitesgamersmafiastorageclans559sponsors400.jpg
247	#BLP-Servers	576	www.BLP-servers.com	homehttpdwebsitesgamersmafiastorageclans576sponsors247.gif
245	SF.Team	580	Ventrilo: #SF.team	homehttpdwebsitesgamersmafiastorageclans580sponsors245.gif
241	s	583	\N	homehttpdwebsitesgamersmafiastorageclans583sponsors241.gif
246	BULLETPROOF.technology	585	www.blp-servers.com	homehttpdwebsitesgamersmafiastorageclans585sponsors246.gif
249	Multicentro de Ocio Zig-Zag	585	www.zigzagmurcia.net	homehttpdwebsitesgamersmafiastorageclans585sponsors249.jpg
312	Firebirdservers	614	www.firebirdservers.com	homehttpdwebsitesgamersmafiastorageclans614sponsors312.jpg
315	Andaina	614	www.Andaina.org	homehttpdwebsitesgamersmafiastorageclans614sponsors315.jpg
255	MasMB	619	www.masMB.com	homehttpdwebsitesgamersmafiastorageclans619sponsors255.gif
258	Google	623	www.google.es	homehttpdwebsitesgamersmafiastorageclans623sponsors258.gif
259	DowHispano	623	dowhispano.com	homehttpdwebsitesgamersmafiastorageclans623sponsors259.jpg
265	WFgaming	641	www.wfgaming.com/	homehttpdwebsitesgamersmafiastorageclans641sponsors265.jpg
285	dominio	641	www.andaina.org/	homehttpdwebsitesgamersmafiastorageclans641sponsors285.jpg
264	Mecahost	644	www.mecahost.com	homehttpdwebsitesgamersmafiastorageclans644sponsors264.png
268	EvadeF	653	www.evadef.com	homehttpdwebsitesgamersmafiastorageclans653sponsors268.gif
269	Niwars	653	www.niwars.com	homehttpdwebsitesgamersmafiastorageclans653sponsors269.jpg
270	Evolution XXI	656	www.evolutionxxi.com	homehttpdwebsitesgamersmafiastorageclans656sponsors270.gif
286	MecaHost	661	www.mecahost.com	homehttpdwebsitesgamersmafiastorageclans661sponsors286.jpg
275	Platanos clan foro	685	usuarios.lycos.es/halflife2/phpBB2/	homehttpdwebsitesgamersmafiastorageclans685sponsors275.gif
276	clan eres un enfermo	685	www.eresunenfermo.net	homehttpdwebsitesgamersmafiastorageclans685sponsors276.png
279	Dominio	696	www.andaina.org/	homehttpdwebsitesgamersmafiastorageclans696sponsors279.jpg
277	Mecahost	702	www.mecahost.com	homehttpdwebsitesgamersmafiastorageclans702sponsors277.gif
278	Psy-World	702	www.psy-world.org	homehttpdwebsitesgamersmafiastorageclans702sponsors278.gif
291	EA GAMES 	714	www.ea.com	homehttpdwebsitesgamersmafiastorageclans714sponsors291.jpg
292	Planet Medal Of Honor	714	www.planetmedalofhonor.com/mohaa/	homehttpdwebsitesgamersmafiastorageclans714sponsors292.gif
290	CubaGamers	728	www.cubagamers.co.nr	homehttpdwebsitesgamersmafiastorageclans728sponsors290.gif
294	No Gravity Game Network	737	www.nggn.net	homehttpdwebsitesgamersmafiastorageclans737sponsors294.gif
297	google	768	www.google.cl	homehttpdwebsitesgamersmafiastorageclans768sponsors297.jpg
298	nokia	768	www.nokia.cl	homehttpdwebsitesgamersmafiastorageclans768sponsors298.jpg
304	NGGN	769	www.nggn.com	homehttpdwebsitesgamersmafiastorageclans769sponsors304.jpg
305	VirT Max	769	www.VirtmaxServers.com	homehttpdwebsitesgamersmafiastorageclans769sponsors305.jpg
306	Monsters Kills	775	mk.gamersmafia.com/	homehttpdwebsitesgamersmafiastorageclans775sponsors306.jpg
327	redCode	778	www.redcode-esports.com/	homehttpdwebsitesgamersmafiastorageclans778sponsors327.jpg
328	Spanish-Arena	778	www.spanish-arena.com	homehttpdwebsitesgamersmafiastorageclans778sponsors328.jpg
323	Platanos	812	www.platanos-clan.tk	homehttpdwebsitesgamersmafiastorageclans812sponsors323.gif
317	Eres un enfermo	812	www.eresunenfermo.net	homehttpdwebsitesgamersmafiastorageclans812sponsors317.png
333	ZONA METALERA	849	spaces.msn.com/members/templometalero/PersonalSpace.aspx?_c02_owner=1&_c=	homehttpdwebsitesgamersmafiastorageclans849sponsors333.jpg
335	Google	849	www.google.es	homehttpdwebsitesgamersmafiastorageclans849sponsors335.jpg
332	GOOGLE	852	www.google.com	homehttpdwebsitesgamersmafiastorageclans852sponsors332.gif
339	Ciber eXoduS	867	www.clan-cce.com	homehttpdwebsitesgamersmafiastorageclans867sponsors339.jpg
343	Wad-Net	868	wad-net.com	homehttpdwebsitesgamersmafiastorageclans868sponsors343.jpg
345	Antenne	888	www.Antenne-IRC.de	homehttpdwebsitesgamersmafiastorageclans888sponsors345.jpg
349	Clan base	893	www.clanbase.com/claninfo.php?cid=863586	homehttpdwebsitesgamersmafiastorageclans893sponsors349.gif
350	4mohers	893	www.4mohers.com	homehttpdwebsitesgamersmafiastorageclans893sponsors350.jpg
347	MedalMania	906	medalmania.shinranet.com/	homehttpdwebsitesgamersmafiastorageclans906sponsors347.gif
351	Google	914	www.google.es	homehttpdwebsitesgamersmafiastorageclans914sponsors351.gif
352	Pc Box	914	www.pcbox.es	homehttpdwebsitesgamersmafiastorageclans914sponsors352.jpg
353	LOS SNIPERS DEL PERU	921	\N	homehttpdwebsitesgamersmafiastorageclans921sponsors353.jpg
358	Firebirdservers.com	928	www.firebirdservers.com	homehttpdwebsitesgamersmafiastorageclans928sponsors358.jpg
359	Andaina.org	928	www.andaina.org	homehttpdwebsitesgamersmafiastorageclans928sponsors359.jpg
355	google	930	www.google.es/	homehttpdwebsitesgamersmafiastorageclans930sponsors355.jpg
356	4soldiers	930	www.4soldiers.net	homehttpdwebsitesgamersmafiastorageclans930sponsors356.png
397	QuakeReligion	936	quakereligion.com/	homehttpdwebsitesgamersmafiastorageclans936sponsors397.png
360	Gatekeepers Guild	941	wtfxd.gamersmafia.com/	homehttpdwebsitesgamersmafiastorageclans941sponsors360.png
366	PUNTOS DE RAID	969	guildwow.host.sk/guild/	homehttpdwebsitesgamersmafiastorageclans969sponsors366.jpg
361	Antenne	970	www.Antenne-IRC.de	homehttpdwebsitesgamersmafiastorageclans970sponsors361.jpg
363	Search	974	\N	homehttpdwebsitesgamersmafiastorageclans974sponsors363.jpg
364	Half-Life 2 Spain	985	www.hl2spain.com	homehttpdwebsitesgamersmafiastorageclans985sponsors364.gif
371	UT	991	4unrealers.com/	homehttpdwebsitesgamersmafiastorageclans991sponsors371.gif
373	REnault EspaÃ±a	991	www.renault.es/index_es.html	homehttpdwebsitesgamersmafiastorageclans991sponsors373.jpg
381	NewLightSystems	992	www.newlightsystems.com/	homehttpdwebsitesgamersmafiastorageclans992sponsors381.jpg
387	DarkCova	992	www.darkcova.com/	homehttpdwebsitesgamersmafiastorageclans992sponsors387.jpg
375	UnrealCl	1002	www.unreal.cl	homehttpdwebsitesgamersmafiastorageclans1002sponsors375.gif
377	WaD-NeT	1019	www.wad-net.com	homehttpdwebsitesgamersmafiastorageclans1019sponsors377.jpg
378	Jump	1019	www.jump.es	homehttpdwebsitesgamersmafiastorageclans1019sponsors378.jpg
389	Don Carpi Pizza	1035	www.doncarpi.com/flash.html	homehttpdwebsitesgamersmafiastorageclans1035sponsors389.jpg
385	BF2 Spain	1036	www.bf2spain.com	homehttpdwebsitesgamersmafiastorageclans1036sponsors385.gif
386	Battlefield spain	1036	www.battlefieldspain.com	homehttpdwebsitesgamersmafiastorageclans1036sponsors386.gif
392	Google	1069	www.Google.es/	homehttpdwebsitesgamersmafiastorageclans1069sponsors392.jpg
393	AMD	1069	\N	homehttpdwebsitesgamersmafiastorageclans1069sponsors393.jpg
407	Need for Speed Underground 2	1096	\N	homehttpdwebsitesgamersmafiastorageclans1096sponsors407.jpg
410	Search & Destroy	1000	\N	CDocumentsandSettingsWuanLuMisdocumentosMisarchivosrecibidosSdmetal.jpg
412	Pwnage-Hosting	993	www.pwnage-hosting.co.uk	pwnagemain.jpg
414	Fun Land Servers	699	http://www.funlandservers.com	CDocumentsandSettingsKeisHoEscritorioFunlanddputa.jpg
415		763		C:\\Documents and Settings\\Mezzo peluqueros\\Mis documentos\\Mis archivos recibidos\\Logo_oficial_VDK_2_retoke.jpg
419	NewlightSystems	994	http://www.newlightsystems.com	nls20051.jpg
170	DowHispano	369	http://www.dowhispano.com/	homehttpdwebsitesgamersmafiastorageclans369sponsors170.jpg
257	4DoW	369	http://4dow.net/	homehttpdwebsitesgamersmafiastorageclans369sponsors257.jpg
420	4GuildWars	369	http://4guildwars.com/	CDocumentsandSettingsxMisdocumentos4gwnew.bmp
421	Guild Wars Official Site	369	http://www.guildwars.com/	CDocumentsandSettingsxMisdocumentosgw_logo.bmp
422	qflash Juegos onliNe	1121	qflash.tk	CDocumentsandSettingsANAFFEMisdocumentoslogoflash2.bmp
\.


--
-- Name: clans_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT clans_sponsors_pkey PRIMARY KEY (id);


--
-- Name: clans_sponsors_clan_id_name; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX clans_sponsors_clan_id_name ON clans_sponsors USING btree (clan_id, name);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT "$1" FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

