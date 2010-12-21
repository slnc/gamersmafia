--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: countriies; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE countriies (
    id integer,
    code character varying,
    name character varying
);


--
-- Data for Name: countriies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY countriies (id, code, name) FROM stdin;
1	ad	Andorra, Principality of
2	ae	United Arab Emirates
3	af	Afghanistan, Islamic State of
4	ag	Antigua and Barbuda
5	ai	Anguilla
6	al	Albania
7	am	Armenia
8	an	Netherlands Antilles
9	ao	Angola
10	aq	Antarctica
11	ar	Argentina
12	arpa	Old style Arpanet
13	as	American Samoa
14	at	Austria
15	au	Australia
16	aw	Aruba
17	az	Azerbaidjan
18	ba	Bosnia-Herzegovina
19	bb	Barbados
20	bd	Bangladesh
21	be	Belgium
22	bf	Burkina Faso
23	bg	Bulgaria
24	bh	Bahrain
25	bi	Burundi
26	bj	Benin
27	bm	Bermuda
28	bn	Brunei Darussalam
29	bo	Bolivia
30	br	Brazil
31	bs	Bahamas
32	bt	Bhutan
33	bv	Bouvet Island
34	bw	Botswana
35	by	Belarus
36	bz	Belize
37	ca	Canada
38	cc	Cocos (Keeling) Islands
39	cf	Central African Republic
40	cd	Congo, The Democratic Republic of the
41	cg	Congo
42	ch	Switzerland
43	ci	Ivory Coast (Cote D'Ivoire)
44	ck	Cook Islands
45	cl	Chile
46	cm	Cameroon
47	cn	China
48	co	Colombia
49	com	Commercial
50	cr	Costa Rica
51	cs	Former Czechoslovakia
52	cu	Cuba
53	cv	Cape Verde
54	cx	Christmas Island
55	cy	Cyprus
56	cz	Czech Republic
57	de	Germany
58	dj	Djibouti
59	dk	Denmark
60	dm	Dominica
61	do	Dominican Republic
62	dz	Algeria
63	ec	Ecuador
64	edu	Educational
65	ee	Estonia
66	eg	Egypt
67	eh	Western Sahara
68	er	Eritrea
69	es	Spain
70	et	Ethiopia
71	fi	Finland
72	fj	Fiji
73	fk	Falkland Islands
74	fm	Micronesia
75	fo	Faroe Islands
76	fr	France
77	fx	France (European Territory)
78	ga	Gabon
79	gb	Great Britain
80	gd	Grenada
81	ge	Georgia
82	gf	French Guyana
83	gh	Ghana
84	gi	Gibraltar
85	gl	Greenland
86	gm	Gambia
87	gn	Guinea
88	gov	USA Government
89	gp	Guadeloupe (French)
90	gq	Equatorial Guinea
91	gr	Greece
92	gs	S. Georgia & S. Sandwich Isls.
93	gt	Guatemala
94	gu	Guam (USA)
95	gw	Guinea Bissau
96	gy	Guyana
97	hk	Hong Kong
98	hm	Heard and McDonald Islands
99	hn	Honduras
100	hr	Croatia
101	ht	Haiti
102	hu	Hungary
103	id	Indonesia
104	ie	Ireland
105	il	Israel
106	in	India
107	int	International
108	io	British Indian Ocean Territory
109	iq	Iraq
110	ir	Iran
111	is	Iceland
112	it	Italy
113	jm	Jamaica
114	jo	Jordan
115	jp	Japan
116	ke	Kenya
117	kg	Kyrgyz Republic (Kyrgyzstan)
118	kh	Cambodia, Kingdom of
119	ki	Kiribati
120	km	Comoros
121	kn	Saint Kitts & Nevis Anguilla
122	kp	North Korea
123	kr	South Korea
124	kw	Kuwait
125	ky	Cayman Islands
126	kz	Kazakhstan
127	la	Laos
128	lb	Lebanon
129	lc	Saint Lucia
130	li	Liechtenstein
131	lk	Sri Lanka
132	lr	Liberia
133	ls	Lesotho
134	lt	Lithuania
135	lu	Luxembourg
136	lv	Latvia
137	ly	Libya
138	ma	Morocco
139	mc	Monaco
140	md	Moldavia
141	mg	Madagascar
142	mh	Marshall Islands
143	mil	USA Military
144	mk	Macedonia
145	ml	Mali
146	mm	Myanmar
147	mn	Mongolia
148	mo	Macau
149	mp	Northern Mariana Islands
150	mq	Martinique (French)
151	mr	Mauritania
152	ms	Montserrat
153	mt	Malta
154	mu	Mauritius
155	mv	Maldives
156	mw	Malawi
157	mx	Mexico
158	my	Malaysia
159	mz	Mozambique
160	na	Namibia
161	nato	NATO (this was purged in 1996 - see hq.nato.int)
162	nc	New Caledonia (French)
163	ne	Niger
164	net	Network
165	nf	Norfolk Island
166	ng	Nigeria
167	ni	Nicaragua
168	nl	Netherlands
169	no	Norway
170	np	Nepal
171	nr	Nauru
172	nt	Neutral Zone
173	nu	Niue
174	nz	New Zealand
175	om	Oman
176	org	Non-Profit Making Organisations (sic)
177	pa	Panama
178	pe	Peru
179	pf	Polynesia (French)
180	pg	Papua New Guinea
181	ph	Philippines
182	pk	Pakistan
183	pl	Poland
184	pm	Saint Pierre and Miquelon
185	pn	Pitcairn Island
186	pr	Puerto Rico
187	pt	Portugal
188	pw	Palau
189	py	Paraguay
190	qa	Qatar
191	re	Reunion (French)
192	ro	Romania
193	ru	Russian Federation
194	rw	Rwanda
195	sa	Saudi Arabia
196	sb	Solomon Islands
197	sc	Seychelles
198	sd	Sudan
199	se	Sweden
200	sg	Singapore
201	sh	Saint Helena
202	si	Slovenia
203	sj	Svalbard and Jan Mayen Islands
204	sk	Slovak Republic
205	sl	Sierra Leone
206	sm	San Marino
207	sn	Senegal
208	so	Somalia
209	sr	Suriname
210	st	Saint Tome (Sao Tome) and Principe
211	su	Former USSR
212	sv	El Salvador
213	sy	Syria
214	sz	Swaziland
215	tc	Turks and Caicos Islands
216	td	Chad
217	tf	French Southern Territories
218	tg	Togo
219	th	Thailand
220	tj	Tadjikistan
221	tk	Tokelau
222	tm	Turkmenistan
223	tn	Tunisia
224	to	Tonga
225	tp	East Timor
226	tr	Turkey
227	tt	Trinidad and Tobago
228	tv	Tuvalu
229	tw	Taiwan
230	tz	Tanzania
231	ua	Ukraine
232	ug	Uganda
233	uk	United Kingdom
234	um	USA Minor Outlying Islands
235	us	United States
236	uy	Uruguay
237	uz	Uzbekistan
238	va	Holy See (Vatican City State)
239	vc	Saint Vincent & Grenadines
240	ve	Venezuela
241	vg	Virgin Islands (British)
242	vi	Virgin Islands (USA)
243	vn	Vietnam
244	vu	Vanuatu
245	wf	Wallis and Futuna Islands
246	ws	Samoa
247	ye	Yemen
248	yt	Mayotte
249	yu	Yugoslavia
250	za	South Africa
251	zm	Zambia
252	zr	Zaire
253	zw	Zimbabwe
\.


--
-- PostgreSQL database dump complete
--

alter table countriies rename to countries;
