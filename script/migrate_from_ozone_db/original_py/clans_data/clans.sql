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
-- Name: clans; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE clans (
    id serial NOT NULL,
    name character varying NOT NULL,
    tag character varying NOT NULL,
    simple_mode boolean DEFAULT true NOT NULL,
    website_external character varying,
    creation_tstamp timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    is_activated boolean DEFAULT false NOT NULL,
    tstamp_registration timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    irc_channel character varying,
    irc_server character varying,
    subdomain character varying NOT NULL,
    o3_websites_dynamicwebsite_id integer
);


--
-- Name: clans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('clans', 'id'), 1151, true);


--
-- Data for Name: clans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clans (id, name, tag, simple_mode, website_external, creation_tstamp, is_activated, tstamp_registration, irc_channel, irc_server, subdomain, o3_websites_dynamicwebsite_id) FROM stdin;
706	Wariors of the sky	=-WTS=-	t	http://wtsq3.madpage.com/	2005-06-07 05:12:34.746988	t	2005-06-07 05:12:34.746988	\N	\N	wts	\N
81	Escuadrón de Batalla Español	[^eBe^]	t	\N	2005-01-27 00:47:59.891243	t	2005-01-27 00:47:59.891243	eBe	irc.americasarmy.com	clanebe	\N
496	.-=*]KV[*=-.	.-=*]KV	t	http://	2005-04-14 21:59:53.448734	t	2005-04-14 21:59:53.448734	\N	\N	kv	\N
416	MOMO CLAN	MOMO	t	http://www.momoclan.com	2005-04-06 01:53:32.841925	t	2005-04-06 01:53:32.841925	\N	\N	momo	\N
357	-#[GoD]#-	Dioses	t	\N	2005-03-28 02:56:06.083371	t	2005-03-28 02:56:06.083371	\N	\N	dioses	\N
355	SaDico	FreAK	t	\N	2005-03-26 22:35:55.889078	t	2005-03-26 22:35:55.889078	\N	\N	freak	\N
353	Darwin	*M¿f*	t	\N	2005-03-26 17:19:00.543725	t	2005-03-26 17:19:00.543725	\N	\N	mf	\N
351	APOCALIPSIS WARRIORS QUAKERS	>AwQ>	t	\N	2005-03-26 02:55:34.876897	t	2005-03-26 02:55:34.876897	\N	\N	awq	\N
514	misterious team	MT	t	http://	2005-04-16 23:27:54.906397	t	2005-04-16 23:27:54.906397	\N	\N	mt	\N
345	Team Sangre	[TS]	t	\N	2005-03-24 00:29:22.880859	t	2005-03-24 00:29:22.880859	\N	\N	ts	\N
344	Argentinos Para El Mundo	*APM*	t	\N	2005-03-23 21:48:54.171442	t	2005-03-23 21:48:54.171442	\N	\N	apm	\N
342	Dosis	2is	t	\N	2005-03-22 23:57:35.269975	t	2005-03-22 23:57:35.269975	\N	\N	2is	\N
335	newreality	NR 	t	\N	2005-03-21 19:05:40.844035	t	2005-03-21 19:05:40.844035	\N	\N	nr	\N
333	NinePlay	9play	t	\N	2005-03-20 23:55:09.785432	t	2005-03-20 23:55:09.785432	\N	\N	9play	\N
332	noC Team	noC	t	\N	2005-03-20 18:19:05.491883	t	2005-03-20 18:19:05.491883	\N	\N	noc	\N
331	-=[T.X.O]=-	DHDHDH	t	\N	2005-03-20 09:40:33.754178	t	2005-03-20 09:40:33.754178	\N	\N	dhdhdh	\N
321	Clan GTAE	GTAE	t	\N	2005-03-15 23:37:10.917167	t	2005-03-15 23:37:10.917167	\N	\N	gtae	\N
317	DarK ClaN CheAteR MulTisquaD	]Dark[	t	\N	2005-03-14 10:42:46.580012	t	2005-03-14 10:42:46.580012	\N	\N	dark	\N
316	n0sTyLe	n0sTyLe	t	\N	2005-03-13 13:30:31.169101	t	2005-03-13 13:30:31.169101	\N	\N	n0style	\N
523	Team-Zero	teamz	t	http://www.teamzero-gaming.tk	2005-04-17 22:13:26.213046	t	2005-04-17 22:13:26.213046	\N	\N	teamz	\N
299	[MTG]	Milico	t	\N	2005-03-05 22:41:23.805044	t	2005-03-05 22:41:23.805044	\N	\N	milico	\N
296	CVG.Crew	CvG	t	\N	2005-03-04 19:49:39.153998	t	2005-03-04 19:49:39.153998	\N	\N	cvg	\N
291	g0 t0 hell gaming	#gTh	t	\N	2005-03-03 02:52:46.986826	t	2005-03-03 02:52:46.986826	\N	\N	gth	\N
284	Prolog	[PR]	t	\N	2005-03-02 15:33:46.373704	t	2005-03-02 15:33:46.373704	\N	\N	pr1	\N
283	r3v0lt ¡	r3v0lt 	t	\N	2005-03-02 13:55:25.317159	t	2005-03-02 13:55:25.317159	\N	\N	r3v0lt1	\N
282	Alliance	ALL|	t	\N	2005-03-02 01:32:10.385238	t	2005-03-02 01:32:10.385238	\N	\N	all	\N
271	maskles!	ms	t	\N	2005-02-27 18:18:33.656679	t	2005-02-27 18:18:33.656679	\N	\N	ms	\N
270	NetproyecT	Netpro	t	\N	2005-02-27 17:51:53.421997	t	2005-02-27 17:51:53.421997	\N	\N	netpro	\N
267	Elite Spanish Forces	=ESF=	t	\N	2005-02-26 16:11:36.023272	t	2005-02-26 16:11:36.023272	\N	\N	esf	\N
266	the_ghost	cod87	t	\N	2005-02-25 23:42:33.290304	t	2005-02-25 23:42:33.290304	\N	\N	cod87	\N
258	Ultra-Violence TeaM	uvT |	t	\N	2005-02-22 11:49:33.717904	t	2005-02-22 11:49:33.717904	\N	\N	uvt1	\N
252	Renegados	-RPR-	t	\N	2005-02-20 22:37:39.89009	t	2005-02-20 22:37:39.89009	\N	\N	rpr	\N
557	Virtual Gamers Alliance	VGA	t	http://www.vga-gaming.com	2005-05-03 18:15:51.266382	t	2005-05-03 18:15:51.266382	\N	\N	vga	\N
579	Idec_Pr0	PipA	t	http://	2005-05-05 19:00:18.626568	t	2005-05-05 19:00:18.626568	\N	\N	pipa	\N
251	zazzer	C.Rclan	t	\N	2005-02-20 19:11:40.926954	t	2005-02-20 19:11:40.926954	\N	\N	crclan	\N
245	los infernales	L.I.F	t	\N	2005-02-19 21:06:24.181654	t	2005-02-19 21:06:24.181654	\N	\N	lif	\N
618	uneXpected	uX	t	http://www.uxclan.com	2005-05-18 11:37:20.143684	t	2005-05-18 11:37:20.143684	\N	\N	ux	\N
244	Clan Barcelona	C_BCN	t	\N	2005-02-19 20:21:39.212466	t	2005-02-19 20:21:39.212466	\N	\N	cbcn	\N
234	Cpg. RüNnY	-|Boa|-	t	\N	2005-02-15 14:21:12.588831	t	2005-02-15 14:21:12.588831	\N	\N	boa	\N
233	DIVISIÓN ESPAÑOLA DE ATAQUE	[DEA]	t	\N	2005-02-15 14:11:12.026034	t	2005-02-15 14:11:12.026034	\N	\N	dea	\N
231	EDELWEISS	-=e-D S	t	\N	2005-02-13 10:44:50.266139	t	2005-02-13 10:44:50.266139	\N	\N	eds	\N
227	141	_141	t	\N	2005-02-12 06:12:16.603362	t	2005-02-12 06:12:16.603362	\N	\N	141	\N
223	NameleS	nL 	t	\N	2005-02-11 23:35:28.080715	t	2005-02-11 23:35:28.080715	\N	\N	nl	\N
221	The Fallen Angels	[TFA]	t	\N	2005-02-11 20:25:30.468291	t	2005-02-11 20:25:30.468291	\N	\N	tfa	\N
197	clan_latino	{LAF}	t	\N	2005-02-08 18:55:20.911422	t	2005-02-08 18:55:20.911422	\N	\N	laf	\N
193	NAM	NAM	t	\N	2005-02-08 14:05:54.172748	t	2005-02-08 14:05:54.172748	\N	\N	nam	\N
192	Klan Instinto Asesino	-Kia-	t	\N	2005-02-07 22:55:58.70548	t	2005-02-07 22:55:58.70548	\N	\N	kia	\N
173	Sir Alex The Lordaeron	hishura	t	\N	2005-02-06 05:50:00.886484	t	2005-02-06 05:50:00.886484	\N	\N	hishura	\N
171	Clan Pro	PRO	t	\N	2005-02-05 14:20:36.918917	t	2005-02-05 14:20:36.918917	\N	\N	pro	\N
163	ZoneKiller	zK	t	\N	2005-02-05 09:58:39.205259	t	2005-02-05 09:58:39.205259	\N	\N	zk1	\N
162	Ultra Violence Team	uvT | 	t	\N	2005-02-05 07:56:06.516664	t	2005-02-05 07:56:06.516664	\N	\N	uvt	\N
105	Tercios Españoles	[TE]	t	\N	2005-01-28 01:22:22.419443	t	2005-01-28 01:22:22.419443	\N	\N	te	\N
87	kLan-Cornudos	kLC	t	\N	2005-01-27 14:51:25.435519	t	2005-01-27 14:51:25.435519	kLC	irc.irc-hispano.org	klc	\N
374	Clan 145	{145}	t	\N	2005-03-30 20:22:03.403109	t	2005-03-30 20:22:03.403109	\N	\N	clan145	\N
155	aGuilas Negras.	aGn - 	t	\N	2005-02-03 20:01:52.281081	t	2005-02-03 20:01:52.281081	aGn.es	Quakenet	agnteam	\N
90	Caos Del Infierno	CI	t	\N	2005-01-27 16:15:06.910662	t	2005-01-27 16:15:06.910662	ci	\N	ci	\N
93	Grupo de Reconocimiento Virtual	{GRV}	t	\N	2005-01-27 17:02:13.247246	t	2005-01-27 17:02:13.247246	\N	\N	grv	\N
158	elite of Killer!	eoK!	t	\N	2005-02-03 21:21:09.99714	t	2005-02-03 21:21:09.99714	eok.sp	Quakenet	eok	\N
427	Cssource	Cs	t	http://www.4source.com	2005-04-07 16:54:29.326547	t	2005-04-07 16:54:29.326547	\N	\N	cs	\N
440	Resisten-T	R-T	t	http://Resisten-T	2005-04-08 13:51:51.308554	t	2005-04-08 13:51:51.308554	\N	\N	rt	\N
10	AbSoluT3	«aS3»	t	\N	2005-01-23 16:46:24.411751	t	2005-01-23 16:46:24.411751	Absolut3	irc.quakenet.org	absolut3	\N
392	GuerraLatina	-=TLW=-	t	http://	2005-04-03 21:49:19.940342	t	2005-04-03 21:49:19.940342	sof2	\N	tlw	\N
106	Sudek	S	t	\N	2005-01-28 10:08:06.616517	t	2005-01-28 10:08:06.616517	\N	\N	sudek	\N
54	zona2r MultiSquad	.zona2r	t	\N	2005-01-26 15:25:39.790244	t	2005-01-26 15:25:39.790244	zona2r-team	irc.quakenet.org	zona2r	\N
39	papas con carne	papas	t	\N	2005-01-26 05:09:39.319169	t	2005-01-26 05:09:39.319169	papas_con_carne	irc.quakenet.org	papasconcarne	\N
109	lol	lol	t	\N	2005-01-28 16:37:16.190075	t	2005-01-28 16:37:16.190075	\N	\N	ultimatees	\N
551	Militares Armados Españoles	[M.A.E]	t	http://www.maeclan.tk	2005-04-29 10:28:13.269206	t	2005-04-29 10:28:13.269206	\N	\N	mae	\N
19	Comandos Pata Negra	CMPN	t	http://www.clancmpn.com	2005-01-23 22:53:00.486661	t	2005-01-23 22:53:00.486661	CMPN	irc.americasarmy.com	cmpn	\N
454	Knighs Of Hell	[KOH]	t	http://	2005-04-08 20:49:08.267455	t	2005-04-08 20:49:08.267455	\N	\N	koh	\N
74	OnePlay	1p	t	\N	2005-01-26 21:54:52.486494	t	2005-01-26 21:54:52.486494	OnePlay	Quakenet	oneplay	\N
71	TrauMâ ReâcTor	[dRâ].	t	\N	2005-01-26 21:30:53.257043	t	2005-01-26 21:30:53.257043	\N	\N	dra	\N
95	The Two Klans	«[T2K]»	t	\N	2005-01-27 18:46:50.025103	t	2005-01-27 18:46:50.025103	T2K_klan	irc.quakenet.prg	t2k	\N
596	ApM)	1	t	http://	2005-05-08 21:49:28.573408	t	2005-05-08 21:49:28.573408	\N	\N	1	\N
535	DarKneSs	DKS	t	http://dks.xyon-servers.com	2005-04-21 22:00:45.052862	t	2005-04-21 22:00:45.052862	Klan-DKS	irc.quakenet.org	dks	\N
652	Deutsch Geschwader des rote Stern	DGS	t	\N	2005-05-26 16:59:45.93644	t	2005-05-26 16:59:45.93644	\N	\N	dgs	\N
666	=Red DevilS!!=	R.Devil	t	http://www.rdevils.com	2005-05-30 13:33:47.533975	t	2005-05-30 13:33:47.533975	\N	\N	rdevil	\N
646	Snipers Force	=]$F[=-	t	http://SnipersForce.gamersmafia.com	2005-05-24 20:24:11.875936	t	2005-05-24 20:24:11.875936	\N	\N	f	\N
707	mega wolf	asas	t	http://	2005-06-07 12:04:26.598884	t	2005-06-07 12:04:26.598884	\N	\N	asas	\N
715	Pacifista Con Colt	pcc	t	http://	2005-06-09 00:38:02.328827	t	2005-06-09 00:38:02.328827	\N	\N	pcc	\N
490	{The KiLLeRs}	fdgdg	t	http://spaces.msn.com/members/detounpokitu	2005-04-13 21:30:51.513941	t	2005-04-13 21:30:51.513941	\N	\N	fdgdg	\N
269	Guardianes del Caos	halo	t	\N	2005-02-27 17:42:46.435749	t	2005-02-27 17:42:46.435749	\N	\N	hl	\N
394	sKillzmuseZ	sKmZ	t	http://	2005-04-04 18:33:12.150787	t	2005-04-04 18:33:12.150787	sKmZ.es	irc.quakenet.org	skmz	\N
667	Clan -=]GDE[=-	Clan	t	http://www.chemy-regget.es.mn	2005-05-30 16:11:03.944478	t	2005-05-30 16:11:03.944478	\N	\N	clan	\N
560	CreativeFrags	CF	t	http://	2005-05-04 17:48:27.80655	t	2005-05-04 17:48:27.80655	CreativeFrags	irc.quakenet.org	cf	\N
411	CLAN POWELL	-{PWL}-	t	http://www.clanpowell.wz.cz	2005-04-05 20:18:07.941653	t	2005-04-05 20:18:07.941653	\N	\N	pwl	\N
434	inFernaL!	[iF]	t	http://www.infernalteam.tk	2005-04-07 21:59:27.253386	t	2005-04-07 21:59:27.253386	\N	\N	if	\N
455	Te Jodes Amigo	[TJA]	t	http://	2005-04-08 21:21:26.428761	t	2005-04-08 21:21:26.428761	\N	\N	tja	\N
27	NII	[NII]	t	\N	2005-01-25 12:06:54.097256	t	2005-01-25 12:06:54.097256	\N	\N	nii	\N
375	Clan Colombia	Colombi	t	\N	2005-03-31 00:50:19.848391	t	2005-03-31 00:50:19.848391	\N	\N	colombi	\N
24	hombre invisible	hi	t	\N	2005-01-24 18:59:32.781201	t	2005-01-24 18:59:32.781201	\N	\N	hi	\N
123	Tibia at Gaming	TaG	t	\N	2005-01-29 23:38:22.047164	t	2005-01-29 23:38:22.047164	tag.es	quakenet	tag	\N
69	[ .: Spanish Empalmator Forces :. ]	SEF	t	\N	2005-01-26 20:49:19.954923	t	2005-01-26 20:49:19.954923	SEF.es	irq.QuakeNet.org	sef	\N
103	Fundas de Raqueta	:>	t	\N	2005-01-27 21:06:45.823231	t	2005-01-27 21:06:45.823231	esosahi	Notenemos	amamoslasraketas	\N
232	NeutralZonE	n-ZonE	t	\N	2005-02-13 11:08:04.339091	t	2005-02-13 11:08:04.339091	NeutralZonE	Quakenet	hjsdjs	\N
124	[NCNC]	[NCNC]	t	\N	2005-01-30 00:33:37.578027	t	2005-01-30 00:33:37.578027	\N	\N	ncnc	\N
253	LiGa Cs 1.6	Liga Cs	t	\N	2005-02-21 20:35:16.873876	t	2005-02-21 20:35:16.873876	\N	\N	ligacs	\N
164	N1ce Sh0t	nS |	t	\N	2005-02-05 12:40:35.561902	t	2005-02-05 12:40:35.561902	NiceShoT (en quaknet)	\N	ns	\N
263	Re[V]olt Gamming	Revolt	t	\N	2005-02-25 17:17:25.130268	t	2005-02-25 17:17:25.130268	\N	\N	revolt2	\N
178	3rd.EYE	3Ye	t	\N	2005-02-06 11:18:48.973581	t	2005-02-06 11:18:48.973581	\N	\N	3ye	\N
107	iMpures	iMp	t	\N	2005-01-28 10:23:40.691906	t	2005-01-28 10:23:40.691906	\N	\N	imp	\N
659	Railing Stones	-=RS=-	t	http://	2005-05-29 04:09:56.264129	t	2005-05-29 04:09:56.264129	\N	\N	rs	\N
202	InetCoffee Klan	icK>	t	\N	2005-02-10 00:52:30.402379	t	2005-02-10 00:52:30.402379	ick.moh	\N	ick	\N
243	Are You Ready ?	AuR	t	\N	2005-02-19 11:23:51.680402	t	2005-02-19 11:23:51.680402	aur.dod	Quakenet	aur1	\N
315	csmv2	#csm.es	t	\N	2005-03-13 00:37:09.863623	t	2005-03-13 00:37:09.863623	csmanager.es	\N	csmnoticias	\N
693	LOS_NIÑOS_DEL_CLARET	TUNDRA	t	http://	2005-06-03 20:06:46.597947	t	2005-06-03 20:06:46.597947	\N	\N	tundra	\N
226	EyeSite	Es	t	\N	2005-02-11 23:58:32.71555	t	2005-02-11 23:58:32.71555	EyeSite	\N	eyesite	\N
538	inserso	<iNsErS	t	http://vlaninserso.sytes.net	2005-04-22 21:22:41.508108	t	2005-04-22 21:22:41.508108	\N	\N	insers	\N
412	seguonline	seg	t	http://	2005-04-05 21:02:48.221589	t	2005-04-05 21:02:48.221589	\N	\N	seg	\N
264	x	x	t	http://	2005-02-25 23:07:57.860776	t	2005-02-25 23:07:57.860776	\N	\N	iso	\N
600	* xTm | Counter-Strike Team	* xTm 	t	http://xtm.remhost.com	2005-05-09 20:06:28.788872	t	2005-05-09 20:06:28.788872	\N	\N	xtm	\N
605	-[DfcS]-	DfcS	t	http://www.clandfcs.tk	2005-05-12 22:02:30.678656	t	2005-05-12 22:02:30.678656	\N	\N	dfcs	\N
672	Imperials Falcons	IF	t	http://	2005-06-01 21:12:29.97002	t	2005-06-01 21:12:29.97002	\N	\N	if1	\N
285	CLan NoCturno	cLNc	t	\N	2005-03-02 20:03:06.899806	t	2005-03-02 20:03:06.899806	\N	\N	clnc	\N
721	Nuevo Imperio Guerrero	niG^	t	http://www.ciberaladino.com	2005-06-11 11:41:21.654926	t	2005-06-11 11:41:21.654926	niG.es	\N	nig	\N
694	Click & Kill	{C&K}	t	http://www.clickandkill.tk	2005-06-03 22:45:52.318042	t	2005-06-03 22:45:52.318042	\N	\N	ck	\N
396	X-DiV	X-DiV '	t	http://	2005-04-04 22:11:49.071212	t	2005-04-04 22:11:49.071212	lleida.cs	irc.quakenet.com	xdiv	\N
338	NoSFeR	LsNp	t	\N	2005-03-22 16:24:12.271777	t	2005-03-22 16:24:12.271777	\N	\N	lsnp	\N
356	spyre	. spyre	t	\N	2005-03-28 02:12:52.08504	t	2005-03-28 02:12:52.08504	\N	\N	spyre1	\N
413	SEGUSOF2	{SEG}	t	\N	2005-04-05 21:17:00.086246	t	2005-04-05 21:17:00.086246	\N	\N	seg1	\N
436	<<*}{ELL*>>	HELL	t	http://www.klanhell.com	2005-04-08 10:39:20.938139	t	2005-04-08 10:39:20.938139	\N	\N	hell	\N
481	RVG-CLAN	ORIGINL	t	http://www.revenge-clan.gratishost.com	2005-04-12 23:07:49.481504	t	2005-04-12 23:07:49.481504	\N	\N	originl	\N
635	Nice to Kill you	N2Ku	t	http://www.n2ku.tk	2005-05-21 19:45:22.262278	t	2005-05-21 19:45:22.262278	\N	\N	n2ku	\N
188	Spanish Virtual Soldiers	VTs	t	\N	2005-02-06 19:21:25.940698	t	2005-02-06 19:21:25.940698	\N	\N	vtsclan	\N
198	UNSKILLEDS	UNS	t	\N	2005-02-08 19:32:19.146811	t	2005-02-08 19:32:19.146811	unskilleds!	Quakenet	uns	\N
376	muller8	xasis	t	\N	2005-03-31 16:46:09.740375	t	2005-03-31 16:46:09.740375	\N	\N	xasis	\N
235	Klan $eguidor del Kamasutra	K$K	t	\N	2005-02-15 20:58:14.439096	t	2005-02-15 20:58:14.439096	\N	\N	kk	\N
189	eQuaLiTy TeaM	[eQaY]	t	\N	2005-02-06 23:34:57.057528	t	2005-02-06 23:34:57.057528	equality.team	Quakenet	eqay	\N
237	Lepra	:Lepra:	t	\N	2005-02-16 19:19:11.582918	t	2005-02-16 19:19:11.582918	Lepra.cs	\N	lepra	\N
318	Moddock	D4	t	\N	2005-03-15 16:01:15.287005	t	2005-03-15 16:01:15.287005	\N	\N	d4	\N
238	Elite Forces in Spanish	-=EFS=-	t	\N	2005-02-17 00:18:29.375993	t	2005-02-17 00:18:29.375993	EFS_Clan	irc.americasarmy.com	clanefs	\N
298	Gods Sexy Powa!	GSP	t	\N	2005-03-05 17:03:43.337665	t	2005-03-05 17:03:43.337665	GSP	irc.cl	gsp1	\N
293	Gominolo`s Team	Ght	t	\N	2005-03-03 23:56:18.814953	t	2005-03-03 23:56:18.814953	\N	\N	ght	\N
302	bf	dfb	t	\N	2005-03-07 20:47:06.236416	t	2005-03-07 20:47:06.236416	dbd	Quakenet	dfbf	\N
341	elx dream team	EdT	t	\N	2005-03-22 21:27:07.471474	t	2005-03-22 21:27:07.471474	\N	\N	edt	\N
615	Re6tance	R6|	t	http://	2005-05-17 17:18:09.753047	t	2005-05-17 17:18:09.753047	\N	\N	r6	\N
697	guerreros de ancaria	sacred	t	http://	2005-06-05 12:42:21.664806	t	2005-06-05 12:42:21.664806	\N	\N	sacred	\N
622	[S.W.A.T]	[SWAT]	t	http://clanswat.org	2005-05-18 19:07:51.338152	t	2005-05-18 19:07:51.338152	\N	\N	swat	\N
716	EstilotAchO	*eTc*	t	http://	2005-06-09 07:21:14.338135	t	2005-06-09 07:21:14.338135	\N	\N	rkf	\N
483	batallon colombia	=[BC]=	t	http://www.batalloncolombia.com	2005-04-12 23:19:47.652845	t	2005-04-12 23:19:47.652845	\N	\N	bc	\N
577	no7den.	No7`	t	\N	2005-05-05 15:03:02.262588	t	2005-05-05 15:03:02.262588	\N	\N	no71	\N
713	LOS CB_	LOS CB_	t	http://	2005-06-08 20:32:54.819078	t	2005-06-08 20:32:54.819078	\N	\N	loscb	\N
102	Smurfs	Smfs	t	\N	2005-01-27 20:31:47.875519	t	2005-01-27 20:31:47.875519	\N	\N	smfs	\N
108	uLTimate	uLT.	t	\N	2005-01-28 15:55:48.620213	t	2005-01-28 15:55:48.620213	uLTimate.es	Quakenet	ultimate	\N
70	Zona de Litrada	zdl	t	\N	2005-01-26 20:58:38.540784	t	2005-01-26 20:58:38.540784	\N	\N	zdl1	\N
67	Zona de litrada	ZdL	t	\N	2005-01-26 20:25:51.872514	t	2005-01-26 20:25:51.872514	\N	\N	zdl	\N
334	play for fun	Pf²	t	\N	2005-03-21 18:45:29.876233	t	2005-03-21 18:45:29.876233	Pf²	irc.quakenet.org	playforfun	\N
377	.:3V:.	.:3V:.	t	\N	2005-03-31 16:49:34.947075	t	2005-03-31 16:49:34.947075	\N	\N	3v1	\N
354	Naruto	Naruto	t	\N	2005-03-26 19:56:04.906943	t	2005-03-26 19:56:04.906943	naruto	irc.quakenet.org	naruto	\N
328	Wind Force	wF	t	\N	2005-03-18 15:26:30.769978	t	2005-03-18 15:26:30.769978	\N	\N	wf	\N
279	Da4Frags	4Frags|	t	\N	2005-03-01 14:50:32.134425	t	2005-03-01 14:50:32.134425	\N	\N	4frags1	\N
273	Beast Team	Besat T	t	\N	2005-02-27 18:28:53.155943	t	2005-02-27 18:28:53.155943	\N	\N	besatt	\N
555	x6tence.FIFA	x6fifa	t	http://x6fifa.gamersmafia.com/	2005-05-03 01:11:43.863554	t	2005-05-03 01:11:43.863554	\N	\N	x6fifa	\N
260	Soldados Españoles Kamikazes!	SeK!	t	\N	2005-02-24 19:38:01.402134	t	2005-02-24 19:38:01.402134	\N	\N	sek	\N
616	Ready For Ro0llzZ	r4r	t	www.clanr4r.tk	2005-05-17 18:00:18.583713	t	2005-05-17 18:00:18.583713	\N	\N	r4r	\N
239	[]SOH[] Shade of the hell	[]SOH[]	t	\N	2005-02-17 14:15:51.742417	t	2005-02-17 14:15:51.742417	\N	\N	soh	\N
361	Hijos Del Amanecer Oscuro	HAO	t	\N	2005-03-28 21:31:37.739832	t	2005-03-28 21:31:37.739832	\N	\N	hao	\N
358	Klan de Insurrectos Armados	|K.I.A|	t	\N	2005-03-28 16:34:47.928749	t	2005-03-28 16:34:47.928749	\N	\N	kia1	\N
206	Selected	Selecte	t	\N	2005-02-10 08:47:31.304776	t	2005-02-10 08:47:31.304776	\N	\N	selecte	\N
630	Cholas Garantizadas	Cg 	t	http://www.cholas-garantizadas.com/index.php	2005-05-20 08:11:08.728259	t	2005-05-20 08:11:08.728259	\N	\N	cg	\N
643	Time of War	[ToW]	t	http://	2005-05-23 12:01:38.636214	t	2005-05-23 12:01:38.636214	\N	\N	tow	\N
731	Klan Empires	KE	t	http://klanempires.es	2005-06-12 18:29:55.96429	t	2005-06-12 18:29:55.96429	\N	\N	ke	\N
224	ZeS	ZeS	t	\N	2005-02-11 23:53:44.669538	t	2005-02-11 23:53:44.669538	\N	\N	zes	\N
140	KillerS off the StorM	KaeSe	t	\N	2005-02-01 17:41:34.242026	t	2005-02-01 17:41:34.242026	\N	\N	kaese	\N
114	Redfiles	rF	t	\N	2005-01-28 23:21:24.427586	t	2005-01-28 23:21:24.427586	\N	\N	rf	\N
110	KLAN-666	666	t	\N	2005-01-28 16:51:42.359976	t	2005-01-28 16:51:42.359976	\N	\N	666	\N
18	team.trauma	trauma	t	\N	2005-01-23 21:51:12.431903	t	2005-01-23 21:51:12.431903	\N	\N	trauma	\N
663	ALEJANDRO	¨¨d¨d¨d	t	http://	2005-05-30 07:01:33.357768	t	2005-05-30 07:01:33.357768	\N	\N	ddd	\N
372	Desciples of Apocalyspe	>DoA<	t	\N	2005-03-30 15:55:33.255056	t	2005-03-30 15:55:33.255056	\N	\N	doa	\N
380	CLAN CV	ESPAÑA	t	\N	2005-03-31 18:27:28.738492	t	2005-03-31 18:27:28.738492	\N	\N	espaa	\N
578	PipA	IdeC	t	http://	2005-05-05 18:59:30.455437	t	2005-05-05 18:59:30.455437	\N	\N	idec	\N
549	AlcalaDeNeitors	aDN	t	http://www.adnclan.com	2005-04-27 15:27:11.285688	t	2005-04-27 15:27:11.285688	\N	\N	adn	\N
593	(Peru).aqp.majes	"PERU"	t	http://han_dien@hotmail.com	2005-05-08 13:34:28.090196	t	2005-05-08 13:34:28.090196	\N	\N	peru	\N
608	Durruti	Buenave	t	\N	2005-05-14 11:03:42.466973	t	2005-05-14 11:03:42.466973	\N	\N	buenave	\N
631	wArning!	wA	t	http://www.warning-team.org/	2005-05-20 11:29:23.244251	t	2005-05-20 11:29:23.244251	\N	\N	wa	\N
657	-eVasion][	-eVasio	t	http://	2005-05-28 05:15:02.575179	t	2005-05-28 05:15:02.575179	\N	\N	evasio	\N
161	DaT	DaT|	t	\N	2005-02-05 00:37:32.770937	t	2005-02-05 00:37:32.770937	\N	\N	dat	\N
384	<|CONVOCADOS|>	DARKS	t	http://	2005-03-31 21:51:05.623246	t	2005-03-31 21:51:05.623246	\N	\N	darks	\N
132	nEAty	|xYx|	t	\N	2005-01-31 12:08:38.285032	t	2005-01-31 12:08:38.285032	\N	\N	xyx	\N
130	||-FUMETAS-||	||-FUME	t	\N	2005-01-31 01:41:34.633083	t	2005-01-31 01:41:34.633083	\N	\N	fume	\N
129	-(fCb)-	x4p	t	\N	2005-01-30 22:06:19.051894	t	2005-01-30 22:06:19.051894	\N	\N	x4p	\N
96	sons Of Another time	sOAt >	t	\N	2005-01-27 19:13:39.146711	t	2005-01-27 19:13:39.146711	\N	\N	soat	\N
85	seLected	seLcted	t	\N	2005-01-27 09:37:35.888553	t	2005-01-27 09:37:35.888553	\N	\N	selcted	\N
79	4Frags.cod	4Frags	t	\N	2005-01-26 23:55:53.102623	t	2005-01-26 23:55:53.102623	\N	\N	4frags	\N
76	iNmune	iNmune	t	\N	2005-01-26 22:28:03.661883	t	2005-01-26 22:28:03.661883	\N	\N	inmune	\N
68	Alianza Beta Clan	ABC	t	\N	2005-01-26 20:30:01.374569	t	2005-01-26 20:30:01.374569	\N	\N	abc	\N
56	eXiLia eSports Team	eXiLia 	t	\N	2005-01-26 18:08:16.634114	t	2005-01-26 18:08:16.634114	\N	\N	exilia	\N
53	iLoGik.e*sports	iLoG!k	t	\N	2005-01-26 14:27:06.17349	t	2005-01-26 14:27:06.17349	\N	\N	ilogk	\N
50	Spec	[spec]	t	\N	2005-01-26 13:53:58.762306	t	2005-01-26 13:53:58.762306	\N	\N	spec	\N
49	clan los X	X	t	\N	2005-01-26 13:50:38.457716	t	2005-01-26 13:50:38.457716	\N	\N	329154243	\N
385	Charlie At Six new	[C6]	t	http://www.charlieatsix.com/	2005-03-31 22:32:58.322584	t	2005-03-31 22:32:58.322584	CharlieAtSix	irc.AmericasArmy.com	c61	\N
48	Smurfs CoD|Clan	SMURFS	t	\N	2005-01-26 13:46:12.637957	t	2005-01-26 13:46:12.637957	\N	\N	smurfs	\N
45	Muerte en el Cielo	MeeC	t	\N	2005-01-26 12:03:31.739569	t	2005-01-26 12:03:31.739569	\N	\N	meec	\N
42	Infantería Móvil	1936	t	\N	2005-01-26 09:50:52.666752	t	2005-01-26 09:50:52.666752	\N	\N	1936	\N
35	Elite Squad	eSquad	t	\N	2005-01-26 04:38:12.012119	t	2005-01-26 04:38:12.012119	\N	\N	esquad	\N
32	Guild Shinigami	Ro	t	\N	2005-01-26 00:22:54.487403	t	2005-01-26 00:22:54.487403	\N	\N	ro	\N
8	D Day Boys	-=DDB=-	t	\N	2005-01-23 15:02:54.207966	t	2005-01-23 15:02:54.207966	\N	\N	ddb	\N
364	Cstrikers	CST	t	\N	2005-03-29 17:08:30.173043	t	2005-03-29 17:08:30.173043	\N	\N	cst	\N
365	clan fumetas	FUMETA	t	\N	2005-03-29 18:50:37.528028	t	2005-03-29 18:50:37.528028	\N	\N	fumeta	\N
719	lawardia	VLGI	t	http://	2005-06-10 16:01:25.807529	t	2005-06-10 16:01:25.807529	\N	\N	vlgi	\N
738	Quake 3 España	Q3S	f	http://	2005-06-15 14:54:17.315802	t	2005-06-15 14:54:17.315802	\N	\N	q3s	\N
742	dfgdfgdfg	dfgdfg	f	http://	2005-06-15 15:07:35.19892	t	2005-06-15 15:07:35.19892	\N	\N	dfgdfg	\N
743	Extreme Cs	XcS ][	t	http://kt.gratishost.com/	2005-06-15 16:56:12.280118	t	2005-06-15 16:56:12.280118	XcS.clan	Quakenet	xcs	\N
744	Q España	·Q|3>	f	http://	2005-06-15 21:38:22.08295	t	2005-06-15 21:38:22.08295	\N	\N	q31	\N
745	·Q|3>	q3	f	http://	2005-06-15 21:39:51.538554	t	2005-06-15 21:39:51.538554	\N	\N	q32	\N
741	asd	asd	f	http://www.asd.gamersmafia.com	2005-06-15 14:55:08.248831	t	2005-06-15 14:55:08.248831	\N	\N	asd	\N
746	camila	camila	f	http://	2005-06-15 21:56:27.633882	t	2005-06-15 21:56:27.633882	\N	\N	camila	\N
747	k	k	f	http://	2005-06-16 00:02:01.561006	t	2005-06-16 00:02:01.561006	\N	\N	k	\N
750	>Q|3<	Q3clan	f	http://	2005-06-16 00:44:16.051992	t	2005-06-16 00:44:16.051992	\N	\N	q3clan	\N
760	Arenas Mafia	Harry	t	http://	2005-06-16 10:45:22.882122	t	2005-06-16 10:45:22.882122	\N	\N	harry	\N
764	samuel	Team|cs	t	http://clan-adiccion.com	2005-06-17 17:11:11.55449	t	2005-06-17 17:11:11.55449	\N	\N	teamcs	\N
766	aggresive	chispa	t	http://	2005-06-18 01:11:39.060843	t	2005-06-18 01:11:39.060843	\N	\N	chispa	\N
662	MagicBox	no cave	t	http://www.clanmbx.com	2005-05-30 03:02:47.627453	t	2005-05-30 03:02:47.627453	MagicBox.bf	quakenet.org	mbx	\N
780	Armada Andaluza	['AA']	t	http://	2005-06-20 20:20:44.048607	t	2005-06-20 20:20:44.048607	\N	\N	aa	\N
784	Clan Legion - CLV	CLV	t	http://clanlegionclv.host.sk	2005-06-21 00:12:47.638483	t	2005-06-21 00:12:47.638483	\N	\N	clv	\N
773	[T3] CLAN	[T3]	t	http://	2005-06-19 13:51:43.312783	t	2005-06-19 13:51:43.312783	\N	\N	roparoa	\N
803	Nenez Galazticoz	NENEZ	t	http://www.nenez.tk	2005-06-25 13:46:49.015253	t	2005-06-25 13:46:49.015253	\N	\N	nenez	\N
813	 Shadow 	shaman	t	http://	2005-06-28 01:05:36.832152	t	2005-06-28 01:05:36.832152	\N	\N	shaman	\N
814	freeStyleZ	fS!	t	http://NoSite.tk	2005-06-28 09:56:47.321	t	2005-06-28 09:56:47.321	\N	\N	fs	\N
816	carlos	G[r]Ox	t	http://clan-grox.com	2005-06-28 16:25:13.598995	t	2005-06-28 16:25:13.598995	\N	\N	grox	\N
817	Ct Forces	Lo Maxi	t	http://	2005-06-29 01:45:44.626507	t	2005-06-29 01:45:44.626507	\N	\N	lomaxi	\N
822	city clan	city_	t	http://city.clan.ut.org	2005-07-01 00:00:55.990183	t	2005-07-01 00:00:55.990183	\N	\N	city	\N
829	Dioses del combate	Dioses|	t	http://www.clan-ddc.es.mw	2005-07-02 14:48:13.801943	t	2005-07-02 14:48:13.801943	\N	\N	dioses1	\N
831	/KBC/	/KBC/	t	http://	2005-07-02 21:53:27.178783	t	2005-07-02 21:53:27.178783	\N	\N	kbc	\N
837	Comandos Pata Negra ** Guild Wars	[CMPN]	t	http://guildwars.clancmpn.com	2005-07-04 13:00:49.030766	t	2005-07-04 13:00:49.030766	\N	\N	cmpn1	\N
840	lOs SiN cLaN	>[LSK]<	t	http://	2005-07-04 16:42:09.406758	t	2005-07-04 16:42:09.406758	\N	\N	lsk	\N
854	BBiGG	BBiGG 	t	http://	2005-07-08 22:29:28.945293	t	2005-07-08 22:29:28.945293	BBiGG.SB	Quakenet	bbigg	\N
855	*fin-padron*	*fin*	t	http://	2005-07-08 23:34:03.525052	t	2005-07-08 23:34:03.525052	mafia	irc.quakenet.org	fin	\N
857	TTT	TTTT	t	http://	2005-07-09 00:22:34.966112	t	2005-07-09 00:22:34.966112	\N	\N	tttt	\N
858	Predsskulls	[PK]	t	http://www.skullsclans.com.mx	2005-07-09 03:38:57.184675	t	2005-07-09 03:38:57.184675	\N	\N	pk	\N
860	Advantage Four	a4.es	t	http://www.a4-esports.es.vg	2005-07-09 23:34:20.301171	t	2005-07-09 23:34:20.301171	\N	\N	a4es	\N
862	COLLONS clan	clls	t	http://www.clancollons.com	2005-07-11 16:55:15.326328	t	2005-07-11 16:55:15.326328	collons.bf	quakenet	clls	\N
886	Warriors of Mohaa	[-WoM-]	t	http://	2005-07-14 22:12:38.469319	t	2005-07-14 22:12:38.469319	\N	\N	wom	\N
901	-Xpedient-	X|	f	\N	2005-07-18 21:52:44.300115	t	2005-07-18 21:52:44.300115	Xpedient	\N	x	\N
907	La Unidad	Unidad	t	http://www.launidad.com	2005-07-19 11:39:46.684106	t	2005-07-19 11:39:46.684106	\N	\N	unidad	\N
900	Ceporros	<CpR>	t	http://	2005-07-18 18:41:57.35277	t	2005-07-18 18:41:57.35277	\N	\N	cpr	\N
916	grupo de salto	GDA	t	http://gda.webcindario.com	2005-07-20 12:11:19.528459	t	2005-07-20 12:11:19.528459	\N	\N	gda1	\N
926	moradores infernales de zona	invadir	t	http://carlomagno212.com	2005-07-22 13:29:19.472369	t	2005-07-22 13:29:19.472369	\N	\N	invadir	\N
927	The Exterminators	hola	t	http://www.necrones.net	2005-07-22 18:11:00.716202	t	2005-07-22 18:11:00.716202	\N	\N	hola	\N
934	supercaracoliyo	super	t	http://	2005-07-23 20:39:04.05101	t	2005-07-23 20:39:04.05101	\N	\N	super	\N
920	Esencial Style	Style	t	\N	2005-07-21 19:13:49.295254	t	2005-07-21 19:13:49.295254	\N	\N	style	\N
534	xXx ajentes secretos	xXx	t	http://www.google.cl	2005-04-21 03:04:59.421978	t	2005-04-21 03:04:59.421978	\N	\N	etd	\N
944	ENVOYS OF THE DEVIL	[ETD]	t	http://www.clanetd.piczo.com/	2005-07-26 19:48:12.874462	t	2005-07-26 19:48:12.874462	\N	\N	etd1	\N
948	TcGM	{TcGM}	t	\N	2005-07-28 00:43:51.736614	t	2005-07-28 00:43:51.736614	\N	\N	tcgm	\N
956	themasters	mast	t	http://	2005-07-28 20:09:27.557849	t	2005-07-28 20:09:27.557849	\N	\N	mast	\N
491	daniel	dano	t	http://	2005-04-14 02:01:13.903958	t	2005-04-14 02:01:13.903958	\N	\N	maf	\N
958	<<-- Counter Strike Clan -->>	CS Clan	t	http://	2005-07-29 20:09:27.924945	t	2005-07-29 20:09:27.924945	\N	\N	csclan	\N
959	Kakan	ImPeRiO	t	http://http:/www.elimperioKakan	2005-07-29 23:56:11.639026	t	2005-07-29 23:56:11.639026	\N	\N	imperio	\N
960	kakan	Imperio	t	http://www.kakan.cl	2005-07-30 00:44:39.230289	t	2005-07-30 00:44:39.230289	ImPeRiO_kakan	\N	imperio1	\N
967	dani	clan	t	http://	2005-07-30 22:34:43.662707	t	2005-07-30 22:34:43.662707	\N	\N	clan1	\N
975	Freeze Nature	-Fn-	t	http://www.q3-fn.tk/	2005-08-02 11:59:53.386911	t	2005-08-02 11:59:53.386911	\N	\N	fn	\N
982	cea	cea	t	http://	2005-08-03 17:47:56.626561	t	2005-08-03 17:47:56.626561	\N	\N	cea	\N
1021	clan d'version	friki	t	http://	2005-08-17 14:42:32.207332	t	2005-08-17 14:42:32.207332	\N	\N	friki	\N
1028	MeXsTA	=MeX=	t	http://www.mexsta.tk	2005-08-18 02:57:21.773375	t	2005-08-18 02:57:21.773375	\N	\N	keonda	\N
1058	clan-EA	sacred 	t	http://	2005-08-26 11:29:45.946011	t	2005-08-26 11:29:45.946011	\N	\N	sacred1	\N
1064	Clan Black Dragon 	[CbD]	t	http://cbd.gamersmafia.com	2005-08-28 01:42:12.679562	t	2005-08-28 01:42:12.679562	\N	\N	cbd	\N
1066	Redfiles COD Team!	RF!	t	http://www.clan.redfiles.net	2005-08-28 13:52:26.261151	t	2005-08-28 13:52:26.261151	redfiles.cod	irc.quakenet.org	rf1	\N
1065	Clan Black Dragons	[CBD]	t	http://cbd.gamersmafia.com	2005-08-28 02:00:04.39848	t	2005-08-28 02:00:04.39848	Clan Black Dragons	irc.quakenet.org	cbd1	\N
1073	Cheeses	[CHE]	t	http://	2005-08-29 12:21:55.289324	t	2005-08-29 12:21:55.289324	\N	\N	che	\N
1082	Militar	Militar	t	http://militar.com	2005-09-01 01:12:06.45056	t	2005-09-01 01:12:06.45056	\N	\N	militar	\N
1085	kerous cerber	12	t	http://	2005-09-01 19:24:43.007994	t	2005-09-01 19:24:43.007994	\N	\N	12	\N
1086	Mexicanos Extremadamente Cabrones	|MxC|	t	http://arcade.ya.com/CLAN-MxC	2005-09-01 19:55:30.250053	t	2005-09-01 19:55:30.250053	\N	\N	mxc	\N
1088	tupamaro	TPM	t	http://	2005-09-02 01:22:23.779585	t	2005-09-02 01:22:23.779585	\N	\N	crivero	\N
1089	Exiliados	EX	t	http://	2005-09-02 23:31:03.334355	t	2005-09-02 23:31:03.334355	\N	\N	ex1	\N
1090	Spanish Team Mohaa	StM|^	t	http://clan-stm.turincon.com/	2005-09-02 23:52:07.380571	t	2005-09-02 23:52:07.380571	\N	\N	stm	\N
1091	FOX HOUND	[FoxH]	t	http://spaces.msn.com/members/ersuperloco/PersonalSpace.aspx?_c01_blogpart=myspace&_c02_owner=1&_c=blogpart	2005-09-03 20:19:08.709964	t	2005-09-03 20:19:08.709964	\N	\N	foxh	\N
1114	The Quakers violents	=TQV=	t	http://=tqv=.gamersmafia.com	2005-09-10 16:28:07.952564	t	2005-09-10 16:28:07.952564	\N	\N	tqv1	\N
1115	aMk	- aMk -	t	http://clanamk	2005-09-10 19:36:26.572045	t	2005-09-10 19:36:26.572045	\N	\N	amk	\N
1063	Blood Hammer	[CBH]	t	http://gamersmafia.com	2005-08-28 01:16:29.049477	t	2005-08-28 01:16:29.049477	Blood Hammer	irc.quakenet.org	cbh	\N
1117	[MKT]	QUAKE 2	t	http://	2005-09-11 19:49:55.395813	t	2005-09-11 19:49:55.395813	\N	\N	quake2	\N
3	st1le	s1	f	\N	2005-01-23 03:01:48.573225	t	2005-01-23 03:01:48.573225	st1le	ign.ie.quakenet.org	s1	331
5	BFSpain	[BFSP]	f	\N	2005-01-23 14:32:37.902222	t	2005-01-23 14:32:37.902222	#bf1942spain	irc.quakenet.org	bfspain	332
13	goroÃ±a Que groÃ±a	[gQg]	f	\N	2005-01-23 18:56:25.848162	t	2005-01-23 18:56:25.848162	gQg	jupiter2.irc-hispano.org	gqg	333
14	Charlie At Six	C6	f	\N	2005-01-23 20:15:24.885191	t	2005-01-23 20:15:24.885191	charlieatsix	irc.americasarmy.com	c6	334
17	Gamers Mafia Staff	GMS	f	\N	2005-01-23 20:28:09.364507	t	2005-01-23 20:28:09.364507	GamersMafia	irc.quakenet.eu.org	gms	335
21	elite force klan ... feel the pain	eFk	f	\N	2005-01-24 11:23:15.745671	t	2005-01-24 11:23:15.745671	eFk	irc.quakenet.org	efk	336
23	TruÃ±eros Fardones	TrÃ»fa	f	\N	2005-01-24 16:32:18.237646	t	2005-01-24 16:32:18.237646	Trufa        	irc.quakenet.eu.org	trufa	337
26	Me La Chupas	mLc	f	\N	2005-01-24 23:24:08.295585	t	2005-01-24 23:24:08.295585	MLC	Hispano	mlc	338
28	ClanNwNTest	CLNWNT	f	\N	2005-01-25 19:06:22.723336	t	2005-01-25 19:06:22.723336	\N	\N	clnwnt	339
29	Respect Clan	[-RC-]	f	\N	2005-01-25 20:07:33.590012	t	2005-01-25 20:07:33.590012	rc.clan	de.quakenet.org	rc	340
30	VamosPorLibre	VPL	f	http://	2005-01-26 00:03:27.6668	t	2005-01-26 00:03:27.6668	\N	\N	vpl	341
34	DaMaGe	DmG	f	\N	2005-01-26 03:25:40.341844	t	2005-01-26 03:25:40.341844	damage!	\N	dmg	342
41	Clan DrinkTeam	|DNK|	f	\N	2005-01-26 08:27:40.521229	t	2005-01-26 08:27:40.521229	drinkteam	irc.irc-hispano.org	dnk	343
43	~un2ward~	~{u2d}~	f	\N	2005-01-26 09:56:00.394621	t	2005-01-26 09:56:00.394621	un2ward	irc.quakenet.org	u2d	344
44	Clan Brutals 	Brutals	f	\N	2005-01-26 10:30:44.069498	t	2005-01-26 10:30:44.069498	\N	\N	brutals	345
46	zoneKiller	zK'	f	\N	2005-01-26 12:30:40.674026	t	2005-01-26 12:30:40.674026	-zK-	Quakenet	zk	346
47	Qiang Shi	qs^	f	\N	2005-01-26 12:50:50.065823	t	2005-01-26 12:50:50.065823	tricking_qs	irc.quakenet.org	qiangshi	347
55	SiLeNT	sLn 	f	\N	2005-01-26 18:06:58.532871	t	2005-01-26 18:06:58.532871	clan.silent	Qnet	clansilent	348
63	-Kajht-	emery	f	\N	2005-01-26 19:05:28.909242	t	2005-01-26 19:05:28.909242	\N	\N	emery	349
66	adask	das	f	\N	2005-01-26 20:09:13.253459	t	2005-01-26 20:09:13.253459	\N	\N	das	350
78	Black And White	[B&W]	f	\N	2005-01-26 22:45:47.581791	t	2005-01-26 22:45:47.581791	baw	\N	bw	351
80	earthquake	earthQ	f	\N	2005-01-27 00:41:49.736927	t	2005-01-27 00:41:49.736927	earthquake	Quakenet	earthquake	352
88	p0p	p0p	f	http://olds.gamersmafia.com	2005-01-27 15:20:13.282278	t	2005-01-27 15:20:13.282278	p0p	quakenet	lastattempt	353
89	Fucking Guiris	-=FG=-	f	\N	2005-01-27 16:10:00.352235	t	2005-01-27 16:10:00.352235	\N	\N	fg	354
94	.: Logic.Game e-Sports 2005 :.	LGame |	f	\N	2005-01-27 17:32:10.344431	t	2005-01-27 17:32:10.344431	logic.game	Quakenet	revolt	355
98	sOAt e-gaming	sOAt	f	\N	2005-01-27 19:17:36.442359	t	2005-01-27 19:17:36.442359	soat.cs	irc.quakenet.org	soat1	356
111	newreality 	NR	f	\N	2005-01-28 19:30:20.343805	t	2005-01-28 19:30:20.343805	newreality	irc.quakenet.org	newreality	357
112	Elite Fifa Spain	efs	f	http://	2005-01-28 22:48:10.808146	t	2005-01-28 22:48:10.808146	efs	irc.quakenet.org	efs	358
115	2 SkilleD	2s >	f	\N	2005-01-29 01:03:08.025972	t	2005-01-29 01:03:08.025972	2skilled 	irc.Quakenet.org	2s	359
122	C. E. I. P. AndrÃ©s de Cervantes	cabra	f	\N	2005-01-29 20:00:27.109579	t	2005-01-29 20:00:27.109579	\N	\N	nada	360
134	.spain	.spain	f	\N	2005-01-31 15:25:42.876907	t	2005-01-31 15:25:42.876907	\N	\N	spain	361
136	Uchiha [UcH] - Warhammer 40k: Dawn of War.	UcH	f	\N	2005-01-31 23:00:51.32838	t	2005-01-31 23:00:51.32838	\N	\N	sp	362
137	4 America's Army	4AA	f	\N	2005-01-31 23:31:56.067831	t	2005-01-31 23:31:56.067831	4AmericasArmy	irc.americasarmy.com	4aa	363
139	Mafia	Â«MÃ¢FÂ»	f	\N	2005-02-01 03:17:52.707074	t	2005-02-01 03:17:52.707074	Mafia	irc.quakenet.org	mafia	364
159	pelleta	pelleta	f	\N	2005-02-03 22:56:27.713132	t	2005-02-03 22:56:27.713132	pelleta	irc.quakenet.org	pelleta	365
160	3volution 	3v	f	\N	2005-02-05 00:13:37.998184	t	2005-02-05 00:13:37.998184	3v.gaming	\N	3v	366
167	SpectroofSky	LuFtwaF	f	\N	2005-02-05 14:02:07.414342	t	2005-02-05 14:02:07.414342	\N	\N	luftwaf	367
170	LuFtWaFFe`s	*[LuF]*	f	\N	2005-02-05 14:05:24.823306	t	2005-02-05 14:05:24.823306	\N	66.246.185.24	luftwaffes	368
172	Darks_Engels	Dark_E	f	\N	2005-02-05 18:43:57.019506	t	2005-02-05 18:43:57.019506	\N	\N	lc	369
187	inmune	inmune	f	\N	2005-02-06 14:58:40.192748	t	2005-02-06 14:58:40.192748	iNmune	\N	inmunecs	370
190	ReC	R[e]C	f	\N	2005-02-06 23:41:24.877484	t	2005-02-06 23:41:24.877484	\N	\N	rec	371
191	Selecion EspaÃ±ola de Quake	ESP.Q3	f	\N	2005-02-07 15:24:07.978279	t	2005-02-07 15:24:07.978279	spain.q3	irc.uk.quakenet.org	q3	372
194	eL Neo	clan Tm	f	\N	2005-02-08 15:52:14.990169	t	2005-02-08 15:52:14.990169	\N	\N	clantm	373
195	alvaro	Clan Tm	f	\N	2005-02-08 15:57:25.632799	t	2005-02-08 15:57:25.632799	\N	\N	clantm1	374
199	The Legendary Murders-inc	[M!]	f	\N	2005-02-09 12:51:42.748359	t	2005-02-09 12:51:42.748359	m-inc	\N	team9	375
207	CurseD	CurseD	f	http://	2005-02-10 19:07:59.447234	t	2005-02-10 19:07:59.447234	\N	\N	cursed	376
208	blood soldiers division	BsD	f	\N	2005-02-10 21:02:24.032889	t	2005-02-10 21:02:24.032889	\N	\N	bsd	377
222	NoCD	DbC	f	\N	2005-02-11 20:30:10.047604	t	2005-02-11 20:30:10.047604	-NoCD-	irc.quakenet.org	nocd	378
236	SelecciÃ³n Andaluza MoH:AA	AnD.MoH	f	\N	2005-02-16 14:03:45.261111	t	2005-02-16 14:03:45.261111	\N	\N	andmoh	379
247	raule	df	f	\N	2005-02-19 23:55:49.530664	t	2005-02-19 23:55:49.530664	\N	\N	df	381
259	neDak	spyre	f	\N	2005-02-24 19:01:59.085107	t	2005-02-24 19:01:59.085107	spyre	irc.quakenet.org	spyre	382
262	ReVolt Gamming	ReVolt 	f	\N	2005-02-25 14:05:13.224708	t	2005-02-25 14:05:13.224708	\N	\N	revolt1	383
268	@ r3v0lt Â¡	r3v0lt	f	\N	2005-02-27 14:09:36.473812	t	2005-02-27 14:09:36.473812	\N	\N	r3v0lt	384
272	Prueba	Pr	f	\N	2005-02-27 18:25:27.753992	t	2005-02-27 18:25:27.753992	\N	\N	pr	385
277	--[ Skilled Teamplay ]--	-[sT]-	f	\N	2005-02-28 21:27:38.395859	t	2005-02-28 21:27:38.395859	st.team	Quakenet	st1	386
278	Command White Dragons	[CWD]	f	\N	2005-03-01 01:08:26.422316	t	2005-03-01 01:08:26.422316	cwd.sp	\N	cwd	387
294	Alianza Templaria	AT	f	http://	2005-03-04 16:15:33.188189	t	2005-03-04 16:15:33.188189	\N	\N	alianzatemplaria	388
295	Spanish Edonkeys	Sp_Ed2k	f	http://www.clan-ed2k.com	2005-03-04 18:28:17.819299	t	2005-03-04 18:28:17.819299	\N	\N	nocabe	389
301	DivisiÃ³n EspaÃ±ola de Ataque	DEA	f	http://www.clan-dea.com	2005-03-07 16:38:03.767647	t	2005-03-07 16:38:03.767647	\N	\N	clandea	390
304	De4thOnE	Death'1	f	\N	2005-03-07 22:39:12.889127	t	2005-03-07 22:39:12.889127	\N	\N	dh1	391
305	Caballeros del Apocalipsis	*CDA*	f	\N	2005-03-07 23:11:47.260446	t	2005-03-07 23:11:47.260446	cda.ut	irc.quakenet.org	cda	392
310	CVG Crew	CVG	f	\N	2005-03-10 19:51:38.16206	t	2005-03-10 19:51:38.16206	\N	\N	cvg1	393
313	enraged	enraged	f	http://enraged.gamersmafia.com	2005-03-10 21:09:05.323768	t	2005-03-10 21:09:05.323768	enraged.es	quakenet	jaen	394
314	~(DEATH MASTERS TEAM)~	~(DMT)~	f	\N	2005-03-11 21:31:25.714811	t	2005-03-11 21:31:25.714811	\N	\N	dmt	395
320	...Smoked unreal klan...	[SuK]	f	\N	2005-03-15 18:57:02.887085	t	2005-03-15 18:57:02.887085	ut.suk	irc.quakenet.org	suk	396
322	Team Assault Commando	[CAT]	f	\N	2005-03-17 01:12:35.334993	t	2005-03-17 01:12:35.334993	\N	\N	catclan	397
329	[ANT]Clan	[ANT]	f	\N	2005-03-18 15:34:29.368817	t	2005-03-18 15:34:29.368817	\N	\N	ant	398
330	DandelionZ KeenZ	dkz	f	\N	2005-03-19 23:53:12.343097	t	2005-03-19 23:53:12.343097	dkz.team	irc.quakenet.org	dkz	399
336	 L@sR|[ADM]	L@sR~	f	\N	2005-03-21 20:10:53.389931	t	2005-03-21 20:10:53.389931	\N	\N	lsr	400
343	Enemy Porfessionals Team	EpT	f	\N	2005-03-23 14:22:19.111234	t	2005-03-23 14:22:19.111234	Ept`sp	irc-quakenet.org	ept	401
346	otro	[Â§ÂµK]	f	http://www.sukland.tk	2005-03-24 21:43:53.489171	t	2005-03-24 21:43:53.489171	ut.suk][	\N	783456624	402
363	VirtuaL EnemY	vy '	f	\N	2005-03-29 13:31:57.573823	t	2005-03-29 13:31:57.573823	vy	quakenet	vy	403
366	Mod: Rising Hell	RH	f	\N	2005-03-29 23:19:57.583782	t	2005-03-29 23:19:57.583782	\N	\N	rh	404
367	Mod & Mapping Unreal Tournament	M&M Ut	f	\N	2005-03-29 23:23:28.070477	t	2005-03-29 23:23:28.070477	Pendiente	tal	modut	405
368	etherNal FraggerS	eFraGs	f	\N	2005-03-30 00:22:18.586444	t	2005-03-30 00:22:18.586444	efrags	irc.quakenet.org	efrags	406
370	CÃ³digo Cero	cc	f	\N	2005-03-30 09:39:45.94374	t	2005-03-30 09:39:45.94374	\N	\N	softout	408
381	Clan BoYS oF HeLL	[BoH]	f	\N	2005-03-31 20:19:49.578661	t	2005-03-31 20:19:49.578661	\N	\N	boh	409
386	Latin Attack Force	LAF	f	http://www.latinclanlaf.galeon.com	2005-03-31 23:54:06.39077	t	2005-03-31 23:54:06.39077	\N	\N	laf1	410
387	bcb	bcb	f	http://	2005-04-01 17:49:41.511809	t	2005-04-01 17:49:41.511809	\N	\N	bcb	411
388	FutureWorld	FW	f	http://	2005-04-01 22:14:36.534527	t	2005-04-01 22:14:36.534527	\N	\N	fw	412
395	Lleida.cs	L.cs	f	http://	2005-04-04 22:05:13.992994	t	2005-04-04 22:05:13.992994	lleida.cs	irc.quakenet.org	lcs	413
402	DevilFighters	dF	f	http://www.devilfighers.tk	2005-04-05 13:13:30.232961	t	2005-04-05 13:13:30.232961	\N	\N	df1	414
403	AKA	ak ' 	f	http://ak	2005-04-05 14:53:10.623078	t	2005-04-05 14:53:10.623078	ak.team	irc.quakenet.org	ak	415
404	Angeles negros	AnG ' 	f	\N	2005-04-05 18:14:08.048136	t	2005-04-05 18:14:08.048136	\N	\N	ang	416
405	Ayuda RO	AyudaRO	f	http://	2005-04-05 19:18:28.070848	t	2005-04-05 19:18:28.070848	\N	\N	ayudaro	417
406	CLAN WAPETONS	[WPT]	f	http://xavi-m-2005.servi-host.net/bienvenido_al_clan_wapetons.htm	2005-04-05 19:52:57.628708	t	2005-04-05 19:52:57.628708	\N	\N	wpt	418
408	sKillmouSerZ	sKill '	f	\N	2005-04-05 20:06:17.905701	t	2005-04-05 20:06:17.905701	sKmZ.es	irc.quakenet.org	fdaffad	419
409	Lleida@cs	@lleida	f	\N	2005-04-05 20:07:41.255765	t	2005-04-05 20:07:41.255765	\N	\N	lleida	420
410	dgasdÃ±gjanfg	adgjasd	f	\N	2005-04-05 20:14:28.300666	t	2005-04-05 20:14:28.300666	\N	\N	adgjasd	421
414	Xtrem Sport	X-Sport	f	http://	2005-04-05 22:20:28.151286	t	2005-04-05 22:20:28.151286	\N	\N	xsport	422
417	FundaciÃ³n Kill Force	~FKF~	f	http://www.fkf-clan.com	2005-04-06 15:47:40.582378	t	2005-04-06 15:47:40.582378	\N	\N	fkf	423
419	piratas & killers group	[P.K.G]	f	http://es.geocities.com/tuning_artola/cambattlefield.html	2005-04-06 19:03:06.601383	t	2005-04-06 19:03:06.601383	piratas & killers group	\N	db	424
421	-=Mw TeAm=- |CI7|	Mwteam	f	http://	2005-04-06 19:21:08.72482	t	2005-04-06 19:21:08.72482	\N	\N	oug	425
422	Los CoÃ±o Bobo	LcB	f	http://www.sanakas.tk	2005-04-06 22:50:49.384943	t	2005-04-06 22:50:49.384943	LcB	irc.quakenet.org	lcb	426
428	tpm	[TpM]	f	http://	2005-04-07 18:28:19.218443	t	2005-04-07 18:28:19.218443	tuputamadre	tpmklan	tpm	427
429	Abyss	Abyss	f	\N	2005-04-07 18:46:25.234114	t	2005-04-07 18:46:25.234114	\N	\N	abyss	428
430	Logic.Game	L.Game	f	\N	2005-04-07 20:01:44.230648	t	2005-04-07 20:01:44.230648	logic.game	irc.Quakenet.org	lgame	429
437	fs	fsf	f	http://	2005-04-08 12:04:46.852721	t	2005-04-08 12:04:46.852721	yeah	irc.quakenet.org	fsf	430
441	ClAn TaNgA	[TaNgA]	f	http://	2005-04-08 14:32:25.611483	t	2005-04-08 14:32:25.611483	tangas	miramitanga	tanga	431
448	HerZau	Hz	f	http://	2005-04-08 16:45:06.866221	t	2005-04-08 16:45:06.866221	\N	\N	hz	432
449	Seleccion EspaÃ±ola Moh:aa	mspain	f	http://	2005-04-08 16:52:52.20375	t	2005-04-08 16:52:52.20375	moh.spain	\N	mspain	433
458	NandeZ	HM	f	http://	2005-04-08 22:27:16.411473	t	2005-04-08 22:27:16.411473	\N	\N	hm	434
459	FoOrTe4	FoOrTe4	f	http://FoOrTe4.com	2005-04-08 22:54:05.995575	t	2005-04-08 22:54:05.995575	\N	\N	foorte4	435
470	drean lost	DL	f	http://	2005-04-09 17:51:54.006579	t	2005-04-09 17:51:54.006579	dl.es	irc.quakenet.org	dl	436
471	survive	survive	f	http://	2005-04-10 22:06:12.812586	t	2005-04-10 22:06:12.812586	-survive-	irc.quakenet.org	survive	437
474	INVICTUS	INVICTU	f	http://	2005-04-11 15:29:30.484171	t	2005-04-11 15:29:30.484171	\N	\N	versus	438
476	XOVE	=XOVE=	f	http://	2005-04-12 01:32:08.568321	t	2005-04-12 01:32:08.568321	\N	\N	xove	439
477	SelecciÃ³n CoD:UO	coduoes	f	http://	2005-04-12 13:18:17.097485	t	2005-04-12 13:18:17.097485	coduo.es	irc.quakenet.org	coduoes	440
478	Banned Brigade	BB	f	http://	2005-04-12 15:48:14.348375	t	2005-04-12 15:48:14.348375	banned-brigade	irc.quakenet.org	stop	441
479	eL ultimo combate	eC	f	http://	2005-04-12 17:42:26.519866	t	2005-04-12 17:42:26.519866	\N	\N	ec	442
484	Low PresSure Clan	[Lp]	f	http://	2005-04-13 01:56:58.797109	t	2005-04-13 01:56:58.797109	\N	\N	lp	443
486	-cOdename:	cOdenam	f	http://	2005-04-13 20:09:10.994565	t	2005-04-13 20:09:10.994565	cOdename	\N	codenam	444
494	mafia	maf	f	http://	2005-04-14 02:25:30.49045	t	2005-04-14 02:25:30.49045	\N	\N	maf1	445
497	KaVo Clan espaÃ±ol	*]KV[*	f	http://	2005-04-14 22:16:32.826114	t	2005-04-14 22:16:32.826114	\N	\N	kv1	446
507	Spanish $hoot	>]s$[>	f	http://	2005-04-15 22:02:35.10996	t	2005-04-15 22:02:35.10996	KaVo	\N	vk	447
508	Wings of War - EspaÃ±a	[CCE]	f	\N	2005-04-15 23:03:39.678727	t	2005-04-15 23:03:39.678727	\N	\N	ces	448
510	pAbloz site	pAbloz	f	http://	2005-04-16 10:22:54.793292	t	2005-04-16 10:22:54.793292	\N	\N	pabloz	449
511	.::BLASTER::.	~BLST~	f	http://usuarios.lycos.es/blstermohaa/	2005-04-16 19:10:39.731612	t	2005-04-16 19:10:39.731612	\N	\N	blst	450
518	Wings of War Hispano	[CSE]	f	http://	2005-04-17 01:52:06.522846	t	2005-04-17 01:52:06.522846	\N	\N	wingses	451
520	Win Tag ClaN	wTc <!>	f	http://	2005-04-17 11:00:31.839556	t	2005-04-17 11:00:31.839556	\N	\N	wtc	452
521	L.GamerZ	L.Gamer	f	http://	2005-04-17 11:03:27.211467	t	2005-04-17 11:03:27.211467	\N	\N	lgamer	453
522	@center	AC	f	http://arrobacenter.gamersmafia.com	2005-04-17 18:01:35.396402	t	2005-04-17 18:01:35.396402	@center	irc.quakenet.org	ac	454
525	[LoS PiTuFoS]	PiTuFoS	f	http://www.mpasoft.com/pitufos	2005-04-19 01:15:41.389509	t	2005-04-19 01:15:41.389509	pitufos.moh	\N	pitufos	455
526	Clan Catalunya	=CCat=	f	http://www.clancat.net	2005-04-19 20:36:10.835186	t	2005-04-19 20:36:10.835186	CCat	irc.de.quakenet.org	ccat	456
531	-=LMA=- 	-=LMA=-	f	http://	2005-04-20 05:05:07.239238	t	2005-04-20 05:05:07.239238	\N	\N	900100	457
533	-=Kill=-	-=Kill=	f	http://	2005-04-21 00:15:51.335561	t	2005-04-21 00:15:51.335561	\N	\N	kill	458
536	Hell Guardians	[H-G]	f	http://HG.gamersmafia.com	2005-04-22 18:24:23.012116	t	2005-04-22 18:24:23.012116	\N	\N	hg	459
539	Netgame-s	nTg	f	http://	2005-04-24 13:07:35.785582	t	2005-04-24 13:07:35.785582	NetGame-S	irc.quakenet.org	ntg	460
540	Torneo de Comunidades Autonomas	-TCA-	f	http://	2005-04-24 14:23:16.238839	t	2005-04-24 14:23:16.238839	\N	\N	tca	461
541	xCenciaL	xCc ' 	f	http://xCencial.gamersmafia.com	2005-04-24 18:50:29.114514	t	2005-04-24 18:50:29.114514	xCenciaL	se.quakenet.org	xcncl	462
542	sKillmouserZ	sKmZ\\	f	http://	2005-04-24 22:58:52.956499	t	2005-04-24 22:58:52.956499	sKmZ.es	irc.quakenet.org	skmz1	463
544	Tatical OPs Maps And Mod	mapsTO	f	http://	2005-04-24 23:10:39.664933	t	2005-04-24 23:10:39.664933	maps-mod-to	maps-mod-to-.IRC	mapsto	464
545	n0-FraggerS	nF	f	\N	2005-04-24 23:37:00.026562	t	2005-04-24 23:37:00.026562	n0-FraggerS	irc.quakenet.org	nf	465
547	undefeated gods	uG	f	http://undefeated.gods.gamersmafia.com	2005-04-26 20:12:25.830006	t	2005-04-26 20:12:25.830006	undefeated.gods	se.quakenet.org	ug	466
552	Extreme killers	Ek	f	http://	2005-04-30 23:06:41.232934	t	2005-04-30 23:06:41.232934	Ek.clan	quakenet	ek	468
553	Team Killers Clan	TKC	f	http://www.teamkillersclan.com	2005-05-01 02:41:29.903153	t	2005-05-01 02:41:29.903153	\N	\N	tkc	469
554	x6tence.AMD	x6AMD|	f	\N	2005-05-03 01:08:11.504332	t	2005-05-03 01:08:11.504332	\N	\N	x6amd	470
556	x6tence.AMD | FIFA	x6.AMD	f	http://	2005-05-03 01:14:00.444572	t	2005-05-03 01:14:00.444572	x6tence	irc.quakenet.org	x6fifa1	471
559	Ultimate	ulti	f	http://	2005-05-04 15:04:43.52054	t	2005-05-04 15:04:43.52054	\N	\N	ulti	472
575	undefeated @ Gods	uGods	f	http://	2005-05-05 00:20:09.654997	t	2005-05-05 00:20:09.654997	undefeated.gods	quakenet	ugods	473
576	no7den	No7	f	http://no7den.gamesmafia.com	2005-05-05 14:53:43.828573	t	2005-05-05 14:53:43.828573	no7den	Quakenet	no7	474
580	sportGeneration	sG	f	http://	2005-05-05 19:24:26.479634	t	2005-05-05 19:24:26.479634	sG.game	Quakenet	sg	475
583	Clan Lon	lon	f	http://	2005-05-06 01:18:12.52638	t	2005-05-06 01:18:12.52638	\N	\N	sssss	476
585	Online-FragS	Online 	f	http://	2005-05-06 11:39:24.776779	t	2005-05-06 11:39:24.776779	Online-Frags	irc.quakenet.org	online	477
586	LOLITA	LOLI	f	http://charlis.gamersmafia.com	2005-05-06 14:58:16.416986	t	2005-05-06 14:58:16.416986	\N	\N	loli	478
587	Silent Soldiers	S.s	f	\N	2005-05-06 20:48:49.744738	t	2005-05-06 20:48:49.744738	Silent-Soldiers	Quakenet	ss	479
588	TMFalkom	TmF	f	http://	2005-05-07 00:35:05.225332	t	2005-05-07 00:35:05.225332	\N	\N	tmf	480
589	Intensity xTreme	ieX	f	http://	2005-05-07 15:59:45.726187	t	2005-05-07 15:59:45.726187	\N	\N	iex	481
591	iex	]i[eX	f	http://	2005-05-07 16:12:58.486419	t	2005-05-07 16:12:58.486419	\N	\N	iex1	482
592	Elhexodo	[EH]	f	http://	2005-05-08 10:16:50.951157	t	2005-05-08 10:16:50.951157	\N	\N	eh	483
594	(Peru)aqp.majes	"Peru"	f	http://	2005-05-08 14:22:54.151681	t	2005-05-08 14:22:54.151681	\N	\N	peru1	484
599	Los Peleadores Del MaÃ±ana	KARMA	f	http://	2005-05-09 00:44:36.31521	t	2005-05-09 00:44:36.31521	\N	\N	karma	485
601	Warner War	WW	f	www.juegodeguerra.com.ar/foro	2005-05-10 06:10:20.655463	t	2005-05-10 06:10:20.655463	\N	\N	ww1	486
602	The UrBz	 GEOS	f	http://www.galeon.hispavista.com/the-urbz-grafiteros	2005-05-10 18:34:08.028092	t	2005-05-10 18:34:08.028092	The_UrbZ	Hispano	geos	487
603	Brigada Infanteria Ligera	B!L	f	http://www.clan-bil.tk	2005-05-10 19:11:56.253805	t	2005-05-10 19:11:56.253805	\N	\N	bl	488
604	KEMUN	kmN	f	http://	2005-05-12 04:31:40.84078	t	2005-05-12 04:31:40.84078	\N	\N	kmn	489
606	PAGINA PERSONAL DE CORSI	Diego	f	http://	2005-05-12 23:30:27.463615	t	2005-05-12 23:30:27.463615	\N	\N	kmn1	490
607	agresive!	avs	f	http://	2005-05-14 01:28:05.885918	t	2005-05-14 01:28:05.885918	agresive	irc.quakenet.org	avs	491
613	Dark Knights	|DKS|	f	http://	2005-05-15 18:46:11.576191	t	2005-05-15 18:46:11.576191	\N	\N	dks1	492
614	xceNciaL	xcNL	f	http://	2005-05-16 11:22:00.872592	t	2005-05-16 11:22:00.872592	XCENCIAL	Quakenet	xcl	493
617	inM|neNt cLaN	inM|neN	f	\N	2005-05-17 19:30:00.484768	t	2005-05-17 19:30:00.484768	inminent	\N	inmnen	494
619	Clan 13	c13	f	http://	2005-05-18 16:45:19.73184	t	2005-05-18 16:45:19.73184	c13	\N	c13	495
620	Dragon	DgN |	f	http://dragon.gamersmafia.com	2005-05-18 18:43:44.693072	t	2005-05-18 18:43:44.693072	\N	\N	dgn	496
621	dragon	DgN	f	http://DgN.gamersmafia.com	2005-05-18 18:58:21.286148	t	2005-05-18 18:58:21.286148	\N	\N	dgn1	497
623	Invictus Exterminators	[I_E]	f	http://	2005-05-19 15:09:04.705174	t	2005-05-19 15:09:04.705174	\N	\N	ie	498
624	- Sports-Generation -	sGen.	f	http://www.sports-generation.tk	2005-05-19 15:14:28.177112	t	2005-05-19 15:14:28.177112	sg.game	irc.quakenet.org	sgen	499
625	Red Skins Clan	RsC	f	http://	2005-05-20 03:41:42.618387	t	2005-05-20 03:41:42.618387	\N	\N	rsc	500
632	Clan Red Stars	CRS 	f	http://	2005-05-20 18:06:45.488743	t	2005-05-20 18:06:45.488743	\N	\N	crs	501
633	clan excite	excite 	f	http://	2005-05-20 18:19:34.956676	t	2005-05-20 18:19:34.956676	excite-gaming	irc.quakenet.org	excite	502
634	3lement^s	|3s|	f	http:// www.clan-elements.ya.st	2005-05-20 20:25:59.407522	t	2005-05-20 20:25:59.407522	3s.cs y 3steam	\N	3s	503
636	eMule-Spanish	eMule	f	http://eMule-Spanish	2005-05-22 03:51:59.962156	t	2005-05-22 03:51:59.962156	eMule-Spanish	ircchat.emule-project.net	emule	504
638	ISMAEL cs:source	900	f	http://www.clangeoespaÃ±a2.es	2005-05-22 16:03:11.660093	t	2005-05-22 16:03:11.660093	\N	\N	900	505
639	CLAN [[G.E.O]]  CS:Source	ISMAEL	f	http://www.counterismael.es	2005-05-22 16:06:29.108151	t	2005-05-22 16:06:29.108151	\N	\N	ismael	506
640	Caballeros Negros	cNsTyLe	f	http://www.caballerosnegros.da.ru	2005-05-22 16:23:17.675968	t	2005-05-22 16:23:17.675968	\N	\N	cnstyle	507
641	Unidad Especial de Intervenciones	[UEI]	f	http://	2005-05-22 20:29:10.772204	t	2005-05-22 20:29:10.772204	\N	\N	uei	508
642	kill the aznar	*kHa*	f	http://	2005-05-22 22:31:45.511842	t	2005-05-22 22:31:45.511842	\N	\N	kha	509
644	Armadas Clan sports	aC	f	http://acgaming	2005-05-23 22:22:05.631981	t	2005-05-23 22:22:05.631981	aC.GaminG	Quakenet	ac1	510
645	Crimson Knights	CK	f	\N	2005-05-24 13:23:02.036269	t	2005-05-24 13:23:02.036269	\N	\N	nwniwa	511
647	killers eleven	leelo's	f	http://	2005-05-24 21:46:33.764048	t	2005-05-24 21:46:33.764048	\N	\N	leelos	512
648	inspired e.sports [Roster Noche]	iNs	f	http://	2005-05-25 16:11:18.441088	t	2005-05-25 16:11:18.441088	inspired.e-sports	Quakenet	ins	513
649	Miembros Silenciosos Narcotraficantes	[M.s.N]	f	http://www.clanmsn.es.mn	2005-05-25 16:56:13.970595	t	2005-05-25 16:56:13.970595	\N	\N	msn	514
650	xtReMe.Gaming	x3M	f	http://www.x3mcs.tk	2005-05-25 17:33:19.780464	t	2005-05-25 17:33:19.780464	x3M.cS	Qnet	x3m	515
653	Zodiac Alliance of Freedom Treaty	ZAFT	f	http://	2005-05-26 19:40:34.875448	t	2005-05-26 19:40:34.875448	\N	\N	zaft	516
654	clan nica	no lo s	f	http://	2005-05-27 17:22:39.622602	t	2005-05-27 17:22:39.622602	\N	\N	nolos	517
655	Night Killers	-=NK=-	f	http://	2005-05-27 19:00:25.335215	t	2005-05-27 19:00:25.335215	\N	\N	nk	518
656	::[uMp]:: Union de Mercenarios Profesionales	uMp #	f	http://	2005-05-27 21:04:00.133303	t	2005-05-27 21:04:00.133303	\N	\N	ump	519
658	Tequila Ginebra Vodka	=TGV=	f	http://	2005-05-28 23:22:48.103745	t	2005-05-28 23:22:48.103745	TGV	irc.quakenet.org	tgv	520
660	Kodename Victory	[KV]	f	http://	2005-05-29 14:56:00.446996	t	2005-05-29 14:56:00.446996	\N	\N	kv2	521
661	Neighbours Of Counter Strike - Server : 62.81.199.18:27016	n8bours	f	http://	2005-05-29 18:00:32.871841	t	2005-05-29 18:00:32.871841	\N	\N	nocs	522
670	Spanish Rangers 	SpR	f	http://	2005-06-01 11:18:02.714877	t	2005-06-01 11:18:02.714877	\N	\N	spr	523
671	Absence	aB	f	http://	2005-06-01 15:06:41.959096	t	2005-06-01 15:06:41.959096	absence.clan	quakenet.org	ab	524
680	Empire Falcons	EF	f	http://	2005-06-01 22:07:29.214724	t	2005-06-01 22:07:29.214724	\N	\N	ef	525
681	Warrior Falcons	WF	f	http://	2005-06-01 22:26:05.448538	t	2005-06-01 22:26:05.448538	\N	\N	wf1	526
683	los40principales	los40	f	http://	2005-06-02 13:17:17.708073	t	2005-06-02 13:17:17.708073	\N	\N	los40	527
685	(Â¯ÂPlAtaN0s-ClAnÂ_)	PlAtAno	f	http://www.platanos-clan.tk	2005-06-03 01:53:08.740602	t	2005-06-03 01:53:08.740602	\N	\N	platan0	528
689	(Â¯ÂPlAtaN0sÂ_)	PlAtaN0	f	http://www.platanos-clan.tk	2005-06-03 01:59:46.766481	t	2005-06-03 01:59:46.766481	\N	\N	platan01	529
691	xtreme.intelligent	xn7 	f	http://xn7.gamersmafia.com	2005-06-03 19:41:30.407775	t	2005-06-03 19:41:30.407775	\N	\N	xn7	530
696	- = Welcome to TeaM-SkilleD Clan = -	TeaM-Sk	f	http://	2005-06-04 15:45:30.998944	t	2005-06-04 15:45:30.998944	TeaM-SkilleD	QuaKenet	preso	531
700	welldone	wd ' 	f	http://	2005-06-05 18:20:25.360853	t	2005-06-05 18:20:25.360853	welldone	irc.quakenet.org	wd	533
702	elite Force klan - multisquad	efk | 	f	http://www.efk-gaming.net	2005-06-06 15:46:21.080926	t	2005-06-06 15:46:21.080926	\N	\N	efk1	534
703	Como cojones se borra un clan? xD	mp	f	http://	2005-06-06 19:55:11.924168	t	2005-06-06 19:55:11.924168	\N	\N	mp	535
704	the_fall_angel	*z3n0n*	f	http://fall_angel.gamersmafia.com/myclans/new	2005-06-06 20:33:06.160109	t	2005-06-06 20:33:06.160109	\N	\N	z3n0n	536
708	Cruzada Sagrada	CS	f	http://	2005-06-07 20:37:43.681011	t	2005-06-07 20:37:43.681011	\N	\N	cs1	537
711	CARABELA QUAKE	QUAKE	f	http://	2005-06-07 23:46:01.74782	t	2005-06-07 23:46:01.74782	\N	\N	quake	538
714	[SelecciÃ³n EspaÃ±ola Femenina]	Spain.F	f	http://	2005-06-08 21:53:09.778268	t	2005-06-08 21:53:09.778268	\N	\N	spainf	539
717	Empire Weapon	EW	f	http://	2005-06-09 19:13:14.883363	t	2005-06-09 19:13:14.883363	\N	\N	ew	540
718	Clan Foro Seat Ibiza	[IBI]	f	http://www.seatibiza.net	2005-06-10 12:01:58.867271	t	2005-06-10 12:01:58.867271	\N	\N	ibi	541
720	AMIGUETES 4EVER	{A4ER}	f	http://usuarios.lycos.es/a4er/	2005-06-11 10:19:53.993752	t	2005-06-11 10:19:53.993752	\N	\N	a4er	542
722	Extreme Killers 	ek	f	http://	2005-06-11 12:30:55.040254	t	2005-06-11 12:30:55.040254	\N	\N	ek1	543
724	The Lost Angles	T.L.A	f	http://galeon.com/tlaclanonline	2005-06-11 14:40:41.351639	t	2005-06-11 14:40:41.351639	\N	\N	tla	544
725	virtual7eam	v7	f	http://	2005-06-11 16:51:06.304973	t	2005-06-11 16:51:06.304973	-v7-	irc.quakenet.org	v7	545
726	need to xterminer	n0x	f	http://	2005-06-11 18:50:43.211286	t	2005-06-11 18:50:43.211286	\N	\N	n0x	546
727	W4	wins4ev	f	http://	2005-06-12 01:34:56.011071	t	2005-06-12 01:34:56.011071	\N	\N	wins4ev	547
728	Wins4ever	W4	f	http://	2005-06-12 01:35:43.326642	t	2005-06-12 01:35:43.326642	-W4-	irc.quakenet.org	w4	548
732	Los Dioses de la Vida	clan dd	f	http://	2005-06-12 23:34:34.210114	t	2005-06-12 23:34:34.210114	\N	\N	clandd	549
733	Fanatic Frags	|FF|	f	http://	2005-06-13 01:40:49.959187	t	2005-06-13 01:40:49.959187	\N	\N	ff	550
734	SniperWolfs	SW	f	http://	2005-06-14 00:16:38.379319	t	2005-06-14 00:16:38.379319	\N	\N	sw	551
737	Gamewizard	-gW-	f	http://	2005-06-14 22:59:49.44318	t	2005-06-14 22:59:49.44318	\N	\N	gw	553
761	<Q|3=	q3clan	f	http://	2005-06-16 13:49:49.304168	t	2005-06-16 13:49:49.304168	\N	\N	q3clan1	554
762	>Q|3=	q-3clan	f	http://	2005-06-16 14:14:32.181904	t	2005-06-16 14:14:32.181904	\N	\N	q33	555
767	Dragonlance	Kenshin	f	http://www.usuarios.lycos.es/kenshinunlimited/	2005-06-18 02:26:00.487721	t	2005-06-18 02:26:00.487721	quake3arenas	quake3arenas	kenshin	557
768	blaster-mohaa	.:BLST:	f	http://	2005-06-18 02:51:07.360416	t	2005-06-18 02:51:07.360416	\N	\N	blst1	558
769	4easy	\\4easy\\	f	http://www.4easy.tk	2005-06-18 10:43:36.526297	t	2005-06-18 10:43:36.526297	4easy.es	Quakenet	4easy	559
771	The second chance	2c	f	\N	2005-06-18 23:24:44.148614	t	2005-06-18 23:24:44.148614	\N	\N	2c	560
774	JSF	JSF	f	http://	2005-06-19 18:08:41.837851	t	2005-06-19 18:08:41.837851	\N	\N	jsf	561
775	[->*[F][mk]*<-] ------*Filial Monsters Killers*----- [->*[F][mk]*<-]	[f*mk]	f	http://	2005-06-19 23:44:23.19183	t	2005-06-19 23:44:23.19183	\N	\N	tsc	562
777	Angeluxo	[lOl]	f	http://www.angelux.tk/	2005-06-19 23:51:08.564483	t	2005-06-19 23:51:08.564483	\N	\N	lol	563
778	Metal Team Warriors	-=MTW=-	f	\N	2005-06-20 16:54:50.168666	t	2005-06-20 16:54:50.168666	\N	irc.quakebet.org	cp	564
785	L0rd	L0rd	f	http://	2005-06-21 00:38:47.687916	t	2005-06-21 00:38:47.687916	\N	\N	l0rd	565
786	Konflux	kf	f	http://	2005-06-21 12:20:45.963989	t	2005-06-21 12:20:45.963989	\N	\N	kf	566
788	Konflux WoW Guild	Konflux	f	http://	2005-06-21 12:41:40.308479	t	2005-06-21 12:41:40.308479	\N	\N	konflux	567
791	carlos vladimir sanchez mendoza	dark_wa	f	http://www.dark_warriors.com.sv	2005-06-21 20:20:19.959195	t	2005-06-21 20:20:19.959195	\N	\N	darkwa	568
793	Viva Chile Mierda	VCM	f	http://	2005-06-22 18:13:04.44336	t	2005-06-22 18:13:04.44336	\N	\N	vcm	570
794	r!de 0n | Team	ride 0n	f	http://	2005-06-24 00:02:34.494886	t	2005-06-24 00:02:34.494886	\N	\N	rde0n	571
797	Clan Aniquiladores Rezagados	[AR]	f	http://	2005-06-24 18:30:46.213128	t	2005-06-24 18:30:46.213128	\N	\N	ar	572
800	La Mano Blanca	L.M.B	f	http://	2005-06-25 00:30:04.180312	t	2005-06-25 00:30:04.180312	\N	\N	lmb	573
801	[3]ternura	]3[ter	f	\N	2005-06-25 00:38:45.514674	t	2005-06-25 00:38:45.514674	\N	\N	3ter	574
804	HardResistance	HR	f	http://HardResistance.gamersmafia.com/	2005-06-25 17:36:38.618494	t	2005-06-25 17:36:38.618494	HardResistance	Quakenet	hr	575
805	Piratas de la Disformidad	=[PD]=	f	http://	2005-06-25 22:17:16.824125	t	2005-06-25 22:17:16.824125	\N	\N	pd	576
806	GoldAngel	GoldAng	f	http://	2005-06-26 18:30:06.039968	t	2005-06-26 18:30:06.039968	\N	\N	goldang	577
808	Snipers-Force	-]$F[-	f	http://	2005-06-26 22:14:47.640189	t	2005-06-26 22:14:47.640189	\N	\N	f1	578
809	[CLaN ZoNCiLLoS]	[CLaN Z	f	http://	2005-06-27 21:13:35.027086	t	2005-06-27 21:13:35.027086	\N	\N	clanz	579
812	CLaN ZoNCiLLoS	C Z	f	http://	2005-06-27 21:18:09.694949	t	2005-06-27 21:18:09.694949	\N	\N	cz	580
815	Clan Premia	Pr >	f	http://	2005-06-28 13:25:34.903274	t	2005-06-28 13:25:34.903274	\N	\N	pr2	581
818	Los Sin Control	L.S.C	f	http://	2005-06-29 21:59:08.177142	t	2005-06-29 21:59:08.177142	\N	\N	lsc	582
820	Call of Duty EspaÃ±a	CodE/	f	http://ComunidaddejugadoresdeCallofDuty@groups.msn.com	2005-06-30 16:52:57.974164	t	2005-06-30 16:52:57.974164	\N	\N	code	583
821	Cantunis's test	Testing	f	http://	2005-06-30 19:18:16.264062	t	2005-06-30 19:18:16.264062	\N	\N	lol1	584
823	=46thid=	46thid	f	http://	2005-07-01 15:58:09.115209	t	2005-07-01 15:58:09.115209	\N	\N	46thid	585
824	45thid	45thid	f	http://45thidclan.net	2005-07-01 16:00:50.7255	t	2005-07-01 16:00:50.7255	enemy territory	45thid	45thid	586
830	eXtrange	eX	f	http://www.extrange-gaming.com	2005-07-02 15:18:44.086936	t	2005-07-02 15:18:44.086936	eXtrange	irc.quakenet.org	ex	587
839	Grupo de asalto	-GDA-	f	\N	2005-07-04 16:23:22.940911	t	2005-07-04 16:23:22.940911	\N	\N	gda	588
841	LOS SIN KLAN Ip : 62.81.199.17:27018  | www.MecaHost.com | KLAN LSK  By P3gOtA Â®	LSK	f	http://	2005-07-04 19:23:31.805365	t	2005-07-04 19:23:31.805365	ClanLSK	Irc-Hispano	lsk1	589
846	Gangsters	-<GS>-	f	http://clangs.gamersmafia.com	2005-07-05 22:56:06.989386	t	2005-07-05 22:56:06.989386	Gangsters	irc.gamersmafia.com	gs	590
849	Eskuadron de la muerte	[SKM]	f	http://	2005-07-06 16:40:50.587438	t	2005-07-06 16:40:50.587438	\N	\N	mcl	591
850	Fusion Team	[FT]	f	http://	2005-07-07 01:32:08.370334	t	2005-07-07 01:32:08.370334	\N	\N	ft	592
851	Mexicanos Xtremos	[MX]	f	http://	2005-07-07 01:51:59.611265	t	2005-07-07 01:51:59.611265	\N	\N	mx	593
852	DARK MEDIEVAL KNIGHTS	D_M_K	f	http://www.clandmk.com	2005-07-07 03:25:36.152721	t	2005-07-07 03:25:36.152721	\N	\N	dmk	594
853	SeX & DesTroy	[SxD]	f	http://	2005-07-07 19:11:45.82385	t	2005-07-07 19:11:45.82385	\N	\N	sxd	595
859	[Nx]*	Nitrous	f	http://	2005-07-09 18:41:07.695982	t	2005-07-09 18:41:07.695982	\N	\N	nitrous	596
861	soldados	[s2*]	f	http://www.soldados.piczo.com	2005-07-10 06:41:09.114172	t	2005-07-10 06:41:09.114172	\N	\N	s2	597
863	BeLmOnT ClAn	(>BC<)	f	http://	2005-07-11 22:55:49.207329	t	2005-07-11 22:55:49.207329	\N	\N	bc1	598
865	BeLmOnT - ClAn | Server IP: 62.81.199.18:27017 | By Â©yvoÂ®	BC	f	http://	2005-07-11 23:29:49.056638	t	2005-07-11 23:29:49.056638	\N	\N	bc2	599
866	TeaM-Skilled	Tsk	f	http://	2005-07-12 14:03:02.741091	t	2005-07-12 14:03:02.741091	\N	\N	tsk	600
867	eXoduS	eXoduS|	f	http://www.clan-cce.com	2005-07-12 17:36:15.083207	t	2005-07-12 17:36:15.083207	-exodus-	ir.quakenet.org	exodus	601
869	Fight Unjust	fU !>	f	http://	2005-07-13 13:59:28.872045	t	2005-07-13 13:59:28.872045	\N	\N	fu	603
874	juas	juas	f	http://	2005-07-13 14:07:54.960274	t	2005-07-13 14:07:54.960274	\N	\N	juas	604
876	fu	fU	f	http://	2005-07-13 14:09:36.543269	t	2005-07-13 14:09:36.543269	\N	\N	fu1	605
877	figth-Unjust	fU Â¡>	f	http://	2005-07-13 14:13:47.107725	t	2005-07-13 14:13:47.107725	\N	\N	fu2	606
881	pr	pr	f	http://	2005-07-14 10:50:59.194424	t	2005-07-14 10:50:59.194424	\N	\N	pr3	607
885	T-clan	[-T-]	f	http://www.t-clan-mohaa.com	2005-07-14 20:14:56.669546	t	2005-07-14 20:14:56.669546	\N	\N	t	608
888	Decisive Gaming	[Dsv]	f	http://	2005-07-15 01:37:44.062835	t	2005-07-15 01:37:44.062835	Decisive.Gaming	IRC.Quakenet.org	dsv	609
892	Danger4ce	D4ce	f	http://	2005-07-15 10:48:41.022294	t	2005-07-15 10:48:41.022294	Danger4ce	Quakenet	d4ce	610
893	- Clan Premia	clanpr	f	http://	2005-07-15 11:06:38.266806	t	2005-07-15 11:06:38.266806	\N	\N	clanpr	611
895	HeadShootClan	-*HSC*-	f	\N	2005-07-15 14:54:35.270025	t	2005-07-15 14:54:35.270025	\N	\N	hsc	612
896	MatarÃ³ Commanders	[Mc]`	f	http://	2005-07-15 18:57:06.179442	t	2005-07-15 18:57:06.179442	Mc.Quak3	irc.quakenet.org	mc	613
898	PhP - Pro Hide Players	PhP	f	http://	2005-07-16 20:33:13.307005	t	2005-07-16 20:33:13.307005	\N	\N	php	614
906	Xpedient	X |	f	http://	2005-07-18 21:58:21.245937	t	2005-07-18 21:58:21.245937	Xpedient	irc.quakenet.org	x1	615
908	Gore Killers	gK	f	http://gore-killers	2005-07-19 17:21:36.189546	t	2005-07-19 17:21:36.189546	gK.eS	irc.quakenet.org	gk	616
911	Asesinos Sin Rencor	]A.s.R[	f	\N	2005-07-19 19:50:16.244154	t	2005-07-19 19:50:16.244154	lol	irc.quakenet.org	asr	617
914	CePoRros	[CpR]	f	http://	2005-07-20 00:18:14.462874	t	2005-07-20 00:18:14.462874	\N	\N	cpr1	618
917	Spanish Masters	MSTRS	f	http://clanmstrs-es.tk3.net/	2005-07-20 15:58:14.441097	t	2005-07-20 15:58:14.441097	\N	\N	mstrs	619
918	Siervos del Diablo	-[s.D]-	f	http://usuarios.lycos.es/clansiervosdeldiablo/	2005-07-20 20:24:58.915679	t	2005-07-20 20:24:58.915679	\N	\N	sd	620
919	QuietaNdie	QuietaN	f	http://	2005-07-21 10:51:49.239831	t	2005-07-21 10:51:49.239831	-Quietadie-	irc.quakenet.org	quietan	621
921	LOS SNIPER DE PERU	COBRA	f	http://WWW.SNIPERDELPERU.COM.PE	2005-07-21 23:19:22.356303	t	2005-07-21 23:19:22.356303	\N	\N	cobra	622
922	|SC| Clan	SC	f	http://	2005-07-22 13:07:11.242416	t	2005-07-22 13:07:11.242416	\N	\N	sc	623
928	Firetohell	ftH	f	http://	2005-07-22 18:26:48.996601	t	2005-07-22 18:26:48.996601	\N	\N	fth	624
929	Chusma de Abrera!!!	CdA!!!	f	http://	2005-07-22 22:24:33.089761	t	2005-07-22 22:24:33.089761	CdA!!!	\N	abrera	625
930	Spanish murderers	#*Sm ~>	f	http://sm.gamersmafia.com	2005-07-23 13:06:04.252157	t	2005-07-23 13:06:04.252157	Spanish murderers	\N	sm	626
932	Argentina-Spain	ArS	f	http://www.freewebs.com/jrsc10/index.htm	2005-07-23 14:49:32.749158	t	2005-07-23 14:49:32.749158	\N	\N	ars	627
933	macrosoft	mct	f	http://	2005-07-23 15:56:35.938116	t	2005-07-23 15:56:35.938116	mct.es	QuakeNet	mct	628
939	neVermind	nVr	f	http://	2005-07-25 20:31:02.772306	t	2005-07-25 20:31:02.772306	\N	\N	nvr	630
941	Gatekeepers	GK	f	http://	2005-07-26 12:51:57.302448	t	2005-07-26 12:51:57.302448	\N	\N	wtfxd	631
942	Esencial Style Crew	Crew	f	http://esencialstyle.gamersmafia.com	2005-07-26 19:20:06.854809	t	2005-07-26 19:20:06.854809	\N	\N	crew	632
945	CoD'waR	[waR]	f	http://	2005-07-26 19:48:56.682239	t	2005-07-26 19:48:56.682239	\N	\N	war	633
946	Silent-Gamers	^sG|	f	http://silent-gamers.gamersmafia.com	2005-07-27 14:48:38.436463	t	2005-07-27 14:48:38.436463	\N	\N	sg1	634
951	Sons Of Death	SoD	f	http://	2005-07-28 11:42:12.890765	t	2005-07-28 11:42:12.890765	\N	\N	sod	635
957	mafiagame	mÃ¡f	f	http://	2005-07-29 11:43:39.06449	t	2005-07-29 11:43:39.06449	\N	\N	maf2	636
965	Lukas	CuP	f	http://	2005-07-30 11:30:30.580179	t	2005-07-30 11:30:30.580179	\N	\N	cup	637
968	Letal Nightmare	LN	f	http://	2005-08-01 20:42:28.549985	t	2005-08-01 20:42:28.549985	\N	\N	ln	638
969	Guardianes del Tiempo	GT	f	http://	2005-08-02 01:31:46.959261	t	2005-08-02 01:31:46.959261	\N	\N	gt	639
970	Mysteriou$	MysT	f	http://	2005-08-02 07:45:14.903748	t	2005-08-02 07:45:14.903748	Mysteriou$	IRC.Quakenet.org	myst	640
973	Mysteriou$ e-Sports	Myst	f	http://	2005-08-02 11:06:34.084086	t	2005-08-02 11:06:34.084086	\N	\N	myst1	641
974	Mysteriou$ e-Sport Club	theMyst	f	http://	2005-08-02 11:10:01.627247	t	2005-08-02 11:10:01.627247	\N	\N	themyst	642
976	Sons Of Liberty	SoL|||	f	http://	2005-08-02 18:52:41.220222	t	2005-08-02 18:52:41.220222	\N	\N	sol	643
979	SonsOfLiberty	SoL	f	http://	2005-08-02 19:12:41.394618	t	2005-08-02 19:12:41.394618	\N	\N	sol1	644
980	GIF	=|GiF|=	f	http://	2005-08-03 16:36:19.866191	t	2005-08-03 16:36:19.866191	\N	\N	gif	645
981	[=MAD=]	[=MAD=]	f	http://	2005-08-03 17:43:46.06436	t	2005-08-03 17:43:46.06436	\N	\N	mad	646
983	-=Por La Razon O La Fuerza=-	-=ROF=-	f	\N	2005-08-03 19:56:15.735515	t	2005-08-03 19:56:15.735515	\N	\N	rof	647
985	Clan -=]FSL[=- [Fugitivos Sin Ley]	FSL	f	http://	2005-08-05 17:25:53.374253	t	2005-08-05 17:25:53.374253	\N	\N	fsl	648
986	nightmare	night	f	http://www.nightmare.dsdcorporation.com	2005-08-05 23:28:17.980563	t	2005-08-05 23:28:17.980563	\N	\N	nghtma	649
988	survivorS	svS	f	http://	2005-08-07 23:01:24.360367	t	2005-08-07 23:01:24.360367	\N	\N	svs	650
991	ASTRO_SP	ASTRO	f	http://	2005-08-08 01:36:32.063916	t	2005-08-08 01:36:32.063916	\N	\N	astro	651
992	Newlight.cod	^NL	f	http://	2005-08-08 17:36:33.449062	t	2005-08-08 17:36:33.449062	nl.es	irc.quakenet.com	nl1	652
993	no-style	nostyle	f	http://	2005-08-09 03:35:48.927969	t	2005-08-09 03:35:48.927969	no-style.ut	irc.quakenet.org	nostyle	653
997	Unidad Condor	U.Condo	f	http://	2005-08-10 11:20:15.770562	t	2005-08-10 11:20:15.770562	\N	\N	ucondo	655
998	']['|X|']['	T|X|T	f	http://	2005-08-10 11:39:23.303472	t	2005-08-10 11:39:23.303472	\N	\N	txt	656
1000	Search & Destroy	-[S&D]-	f	http://	2005-08-11 04:17:51.842467	t	2005-08-11 04:17:51.842467	\N	\N	sd1	657
1001	CLAN DE HEROES	CDH	f	\N	2005-08-11 12:43:01.8679	t	2005-08-11 12:43:01.8679	\N	\N	cdh	658
1002	ThunderCrash	Malcolm	f	http://	2005-08-13 04:04:27.787248	t	2005-08-13 04:04:27.787248	\N	\N	malcolm	659
1003	CLAN  	-|P*K*O	f	http://	2005-08-14 19:29:51.440197	t	2005-08-14 19:29:51.440197	\N	\N	pko	660
1004	CLAN -|P*K*O*|- 	P*K*O*	f	http://	2005-08-14 19:31:37.554514	t	2005-08-14 19:31:37.554514	\N	\N	pko1	661
1005	Clan -|P*K*O*|	PKO	f	http://	2005-08-14 19:35:55.729862	t	2005-08-14 19:35:55.729862	\N	\N	pko2	662
1006	Clan -|P*K*O*|-	clanPKO	f	http://	2005-08-14 19:39:15.261649	t	2005-08-14 19:39:15.261649	\N	\N	clanpko	663
1009	<[  P - tas comando Terrorista  ]>	PcT#	f	\N	2005-08-14 21:33:06.997856	t	2005-08-14 21:33:06.997856	\N	\N	pct	664
1010	Patches Team	PT|	f	http://	2005-08-15 17:33:05.810908	t	2005-08-15 17:33:05.810908	\N	\N	pt	665
1011	Hail And Kill	-HAK-	f	\N	2005-08-15 21:26:45.671501	t	2005-08-15 21:26:45.671501	\N	\N	hak	666
1012	Viciaos-Nocturnos	Vn	f	http://	2005-08-16 20:22:11.857	t	2005-08-16 20:22:11.857	viciaos-nocturnos	\N	netg	667
1017	2excellent	2eX][	f	http://	2005-08-17 00:28:41.99166	t	2005-08-17 00:28:41.99166	\N	\N	2ex	668
1019	electronic mind	e.mind	f	http://	2005-08-17 14:22:29.235241	t	2005-08-17 14:22:29.235241	e.mind	Quakenet	emind	669
1022	.:(CLD):.Clan Los Destructores	CLD	f	http://www.cld.es.kz	2005-08-17 14:44:31.018165	t	2005-08-17 14:44:31.018165	\N	\N	cld	670
1026	MEX_==_STA	chikili	f	http://www.mexsta.tk	2005-08-18 02:42:30.636026	t	2005-08-18 02:42:30.636026	\N	\N	chikili	671
1029	Alejandro	4n7r4X	f	http://	2005-08-18 04:52:37.755756	t	2005-08-18 04:52:37.755756	\N	\N	4n7r4x	672
1030	-=Cobras=-	Cobras	f	http://	2005-08-18 14:25:20.596612	t	2005-08-18 14:25:20.596612	\N	\N	cobras	673
1031	CLaN DaRK SoLDieRS	|DS|	f	http://www.clands.ngsites.com	2005-08-18 21:06:27.092687	t	2005-08-18 21:06:27.092687	\N	\N	ds	674
1032	101 aerotransportada	1A	f	http://zda-bv.com	2005-08-19 00:06:28.140381	t	2005-08-19 00:06:28.140381	\N	\N	zdabv	675
1036	EAE	EAE	f	http://	2005-08-19 15:15:59.26901	t	2005-08-19 15:15:59.26901	\N	\N	eae	677
1037	|Wat Rocket|	|WR|	f	http://	2005-08-19 16:18:19.328679	t	2005-08-19 16:18:19.328679	\N	\N	wr	678
1039	Noobs In Floor	NiF	f	http://	2005-08-21 12:30:30.569945	t	2005-08-21 12:30:30.569945	\N	\N	nif	679
1040	Fade2Black	F2B	f	http://	2005-08-21 19:11:12.391034	t	2005-08-21 19:11:12.391034	\N	\N	f2bb	680
1042	Fade2Black A	f2b	f	http://	2005-08-22 01:57:15.347464	t	2005-08-22 01:57:15.347464	\N	\N	f2b	681
1043	EL CUARTEL LEPANTO	E.C.L.	f	http://	2005-08-22 17:34:36.551204	t	2005-08-22 17:34:36.551204	\N	\N	ecl	682
1044	High Ping Masters	HPM	f	http://	2005-08-23 17:09:20.146531	t	2005-08-23 17:09:20.146531	\N	\N	hpm	683
1053	CS EspaÃ±ol	89ers	f	http://groups.msn.com/csespana	2005-08-25 09:48:59.183684	t	2005-08-25 09:48:59.183684	\N	\N	89ers	684
1054	KLanKataklan	[KlK]	f	http://www.dowhispano.com	2005-08-25 21:31:10.228481	t	2005-08-25 21:31:10.228481	\N	\N	klk	685
1055	Rapid Reacion Force	[RRF]	f	http://www.reaccionrapida.com/	2005-08-26 11:11:19.376419	t	2005-08-26 11:11:19.376419	\N	\N	rrf	686
1059	xTreem	xTreem	f	http://	2005-08-26 16:24:46.042433	t	2005-08-26 16:24:46.042433	\N	\N	xtreem	687
1060	sexy Quakers	sQ	f	http://	2005-08-27 09:11:02.697006	t	2005-08-27 09:11:02.697006	sQ	irc.hispano	sq	688
1061	experTs	exT	f	http://	2005-08-27 11:13:14.593394	t	2005-08-27 11:13:14.593394	experTs	IRC.Quakenet.org	ext	689
1069	Black Dragons	[BD]	f	http://gamersmafia.com/myclans/new/	2005-08-28 14:47:19.232401	t	2005-08-28 14:47:19.232401	Black Dragons	irc.quakenet.org	bd	690
1070	Division Baker	|D.B|	f	http://www.clan-db.es.mn	2005-08-28 15:29:27.102009	t	2005-08-28 15:29:27.102009	\N	\N	db1	691
1075	Paguina del clan [SpV].Cz	[SpV]	f	http://	2005-08-30 16:21:05.057527	t	2005-08-30 16:21:05.057527	\N	\N	spv	693
1076	TimeLords	TL	f	http://	2005-08-31 00:49:23.512709	t	2005-08-31 00:49:23.512709	\N	\N	tl	694
1081	fortea	fortea^	f	http://	2005-08-31 23:55:29.739418	t	2005-08-31 23:55:29.739418	FoOrTe4	QkneT	fortea	695
1084	militar	militar	f	http://	2005-09-01 01:17:35.915121	t	2005-09-01 01:17:35.915121	\N	\N	militar1	696
1087	DeathONE	N1~	f	http://deathone.tk	2005-09-01 23:51:10.097927	t	2005-09-01 23:51:10.097927	\N	\N	n11	697
1092	North-AnXiety	NX | 	f	http://	2005-09-05 13:20:35.490187	t	2005-09-05 13:20:35.490187	\N	\N	nx	698
1093	caracales	nievlas	f	http://	2005-09-07 04:28:13.443325	t	2005-09-07 04:28:13.443325	\N	\N	nievlas	699
1094	Knight Online	KGO	f	http://www.knightonlineworld.com	2005-09-07 11:58:50.331822	t	2005-09-07 11:58:50.331822	\N	\N	kgo	700
1096	Orwin's Team	Oh Baby	f	http://	2005-09-08 04:27:08.890171	t	2005-09-08 04:27:08.890171	\N	\N	ohbaby	701
1097	Jinetes de Narou	JdN	f	http://	2005-09-08 16:48:54.775743	t	2005-09-08 16:48:54.775743	\N	\N	jdn	702
1098	Soldiers Of Avalon	Â»SÃ¸AÂ«	f	http://soateam.forumactif.com/	2005-09-08 19:23:12.690486	t	2005-09-08 19:23:12.690486	\N	\N	sa	703
1099	Todos Queremos Violencia	TQV	f	http://	2005-09-08 22:18:37.663627	t	2005-09-08 22:18:37.663627	\N	\N	tqv	704
1101	Silent-gamers	^sG |	f	http://	2005-09-09 17:18:31.414402	t	2005-09-09 17:18:31.414402	silent-gamers	Qnet	sg2	706
1102	The Fast Furious	* RyF *	f	http://	2005-09-10 02:08:17.506202	t	2005-09-10 02:08:17.506202	\N	\N	ryf	707
1108	- - - The Fast Furious - - -	 RyF 	f	http://	2005-09-10 05:09:08.973551	t	2005-09-10 05:09:08.973551	\N	\N	ryf1	708
1109	- - -The Fast Furious - - -	- RyF -	f	http://	2005-09-10 05:11:39.774055	t	2005-09-10 05:11:39.774055	\N	\N	ryf2	709
1116	Skin Hammer	[SH]	f	http://gamersmafia.com	2005-09-10 20:28:21.674531	t	2005-09-10 20:28:21.674531	\N	\N	sh	710
1118	The Klan of the Victory	TKV	f	http://	2005-09-13 10:55:44.409309	t	2005-09-13 10:55:44.409309	\N	\N	tkv	711
1120	The Klan of the Soldiers	TKS	f	http://	2005-09-13 11:35:04.040952	t	2005-09-13 11:35:04.040952	\N	\N	tks	712
868	Brigada InfanterÃ­a Ligera	BIL	f	http://	2005-07-12 18:38:28.949457	t	2005-07-12 18:38:28.949457	\N	\N	bil	602
1122	fast destruction	.::FD::.	t	\N	2005-09-16 23:06:29.11311	t	2005-09-16 23:06:29.11311	\N	\N	fd	\N
1123	cs_mix	MIX	f	\N	2005-09-17 10:34:50.615523	t	2005-09-17 10:34:50.615523	\N	\N	mix	753
1124	prueba	prueba	f	\N	2005-09-17 10:38:11.922888	t	2005-09-17 10:38:11.922888	\N	\N	prueba	754
369	Clan Blood Fists	[CBF]	f	\N	2005-03-30 03:00:20.169156	t	2005-03-30 03:00:20.169156	#Blood-Fists	ircchat.emule-project.net	cbf	407
240	The Guiri Killers	TgK	f	\N	2005-02-17 20:25:46.310546	t	2005-02-17 20:25:46.310546	\N	\N	tgk	380
1125	Counter Strike Valdeorras	|C.S.V|	f	\N	2005-09-19 23:16:16.52701	t	2005-09-19 23:16:16.52701	C_S_V	irc.quakenet.org	csv	759
792	Dragon Ball Z	>dbZ<	f	http://	2005-06-21 21:45:44.005269	t	2005-06-21 21:45:44.005269	\N	\N	dbz	569
736	[->*[MK]*<-] The Monsters Kills [->*[MK]*<-] Disfruta de nuestra web...!	*[MK]*	f	http://mkills	2005-06-14 02:43:00.681019	t	2005-06-14 02:43:00.681019	\N	62.81.199.188:27015  | www.MecaHost.com |  Clan  [->*[MK]*<-]	mk	552
699	Clan DePuta	[DePuta]	f	http://	2005-06-05 16:05:09.988574	t	2005-06-05 16:05:09.988574	\N	\N	dputa	532
936	Quakers Connection Interrupt 	[CiQ]	f	http://	2005-07-24 03:01:59.40503	t	2005-07-24 03:01:59.40503	\N	213.190.3.5:27965	ciq	629
763	Vastagos de la Deshonra	|VDK|	f	http://	2005-06-17 12:53:40.282197	t	2005-06-17 12:53:40.282197	\N	\N	vdk	556
550	Dioses del Olimpo	DdO	f	http://	2005-04-28 23:35:18.096159	t	2005-04-28 23:35:18.096159	#CLaN_DdO	\N	ddo	467
1130	FusioN	.:Fusion:.	f	\N	2005-09-24 22:37:57.803897	t	2005-09-24 22:37:57.803897	\N	\N	fusion	772
1131	SPYRE GAMING	SPYRE.winuker	f	\N	2005-09-25 18:19:24.157873	t	2005-09-25 18:19:24.157873	#SPYRE	irc.quakenet.org	spyrewinuker	774
994	niceone	niceone	f	http://	2005-08-09 21:01:59.041111	t	2005-08-09 21:01:59.041111	#niceone	213.149.244.45:27032	n1	654
1035	Tordera Team	TT |	f	http://	2005-08-19 14:21:50.559095	t	2005-08-19 14:21:50.559095	#torderateam	irc.quakenet.org	tt	676
1100	<<*[El KlAn]*>> | By Â©yvoÂ® & Friends	<<*[EK]*>>	f	http://	2005-09-09 01:05:13.939293	t	2005-09-09 01:05:13.939293	<<*[EK]*>>	irc.quakenet.org	ek2	705
1139	CLAN -=[TRoK].Cz=-	-=[TRoK].Cz]=-	f	\N	2005-09-30 20:55:38.433339	t	2005-09-30 20:55:38.433339	\N	\N	trokcz	787
1141	CLAN De Cz -=[TRoK.Cz]=--	-=[TRoK.Cz]=--	f	\N	2005-10-01 09:41:14.247955	t	2005-10-01 09:41:14.247955	\N	\N	trokcz1	790
1071	Paguina del clan -=[TRoK.Cz]=-	-=[TRoK.Cz]=-	f	http://www.claninf.es	2005-08-28 20:29:57.101855	t	2005-08-28 20:29:57.101855	\N	\N	inf	692
1142	M O C O S	MoCoS	t	\N	2005-10-01 11:57:35.519999	t	2005-10-01 11:57:35.519999	\N	\N	mocos	\N
1143	NewLevel Gaming	nL	f	\N	2005-10-01 16:06:29.606485	t	2005-10-01 16:06:29.606485	#NewLevel 	irc.quakenet.org	nl2	792
1148	Cuellos Pelaos	[^CP^]	t	\N	2005-10-05 14:10:49.061222	t	2005-10-05 14:10:49.061222	\N	\N	cp1	\N
1121	The Klan of Railers	TKR	f	http://	2005-09-13 14:29:57.968846	t	2005-09-13 14:29:57.968846	\N	\N	tkr	713
1149	TKR		t	\N	2005-10-05 21:08:07.251978	t	2005-10-05 21:08:07.251978	\N	\N		\N
1150	clan maÃ±os	Ma.oS!$!	t	\N	2005-10-06 15:27:53.467027	t	2005-10-06 15:27:53.467027	\N	\N	maos	\N
1151	Tactical Game	'TG'	f	\N	2005-10-06 17:53:47.618325	t	2005-10-06 17:53:47.618325	#tactical.g	Quakenet	tg	801
\.


--
-- Name: clans_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_name_key UNIQUE (name);


--
-- Name: clans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_pkey PRIMARY KEY (id);


--
-- Name: clans_tag_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_tag_key UNIQUE (tag);


--
-- Name: clans_subdomain; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX clans_subdomain ON clans USING btree (subdomain);


--
-- Name: clans_tag; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX clans_tag ON clans USING btree (tag);


--
-- Name: clans_o3_websites_dynamicwebsite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_o3_websites_dynamicwebsite_id_fkey FOREIGN KEY (o3_websites_dynamicwebsite_id) REFERENCES o3_websites.dynamicwebsites(id) MATCH FULL ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

