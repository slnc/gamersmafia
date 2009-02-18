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
-- Name: clans_groups; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE clans_groups (
    id serial NOT NULL,
    name character varying NOT NULL,
    type_id integer NOT NULL,
    clan_id integer
);


--
-- Name: clans_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('clans_groups', 'id'), 1384, true);


--
-- Data for Name: clans_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clans_groups (id, name, type_id, clan_id) FROM stdin;
547	Clan Leaders	1	441
548	Miembros del clan	2	441
587	Clan Leaders	1	476
588	Miembros del clan	2	476
5	Clan Leaders	1	3
6	Miembros del clan	2	3
595	Clan Leaders	1	481
596	Miembros del clan	2	481
9	Clan Leaders	1	5
10	Miembros del clan	2	5
11	Clan Leaders	1	8
12	Miembros del clan	2	8
13	Clan Leaders	1	10
14	Miembros del clan	2	10
459	Clan Leaders	1	374
460	Miembros del clan	2	374
17	Clan Leaders	1	13
18	Miembros del clan	2	13
19	Clan Leaders	1	14
20	Miembros del clan	2	14
21	Clan Leaders	1	17
22	Miembros del clan	2	17
23	Clan Leaders	1	18
24	Miembros del clan	2	18
25	Clan Leaders	1	19
26	Miembros del clan	2	19
27	Clan Leaders	1	21
28	Miembros del clan	2	21
561	Clan Leaders	1	449
562	Miembros del clan	2	449
31	Clan Leaders	1	23
32	Miembros del clan	2	23
33	Clan Leaders	1	24
34	Miembros del clan	2	24
643	Clan Leaders	1	535
644	Miembros del clan	2	535
37	Clan Leaders	1	26
38	Miembros del clan	2	26
39	Clan Leaders	1	27
40	Miembros del clan	2	27
41	Clan Leaders	1	28
42	Miembros del clan	2	28
43	Clan Leaders	1	29
44	Miembros del clan	2	29
45	Clan Leaders	1	30
46	Miembros del clan	2	30
47	Clan Leaders	1	32
48	Miembros del clan	2	32
465	Clan Leaders	1	377
466	Miembros del clan	2	377
51	Clan Leaders	1	34
52	Miembros del clan	2	34
53	Clan Leaders	1	35
54	Miembros del clan	2	35
55	Clan Leaders	1	39
56	Miembros del clan	2	39
57	Clan Leaders	1	41
58	Miembros del clan	2	41
59	Clan Leaders	1	42
60	Miembros del clan	2	42
61	Clan Leaders	1	43
62	Miembros del clan	2	43
63	Clan Leaders	1	44
64	Miembros del clan	2	44
65	Clan Leaders	1	45
66	Miembros del clan	2	45
67	Clan Leaders	1	46
68	Miembros del clan	2	46
69	Clan Leaders	1	47
70	Miembros del clan	2	47
71	Clan Leaders	1	48
72	Miembros del clan	2	48
73	Clan Leaders	1	49
74	Miembros del clan	2	49
75	Clan Leaders	1	50
76	Miembros del clan	2	50
77	Clan Leaders	1	53
78	Miembros del clan	2	53
79	Clan Leaders	1	54
80	Miembros del clan	2	54
81	Clan Leaders	1	55
82	Miembros del clan	2	55
83	Clan Leaders	1	56
84	Miembros del clan	2	56
471	Clan Leaders	1	384
472	Miembros del clan	2	384
87	Clan Leaders	1	63
88	Miembros del clan	2	63
89	Clan Leaders	1	66
90	Miembros del clan	2	66
91	Clan Leaders	1	67
92	Miembros del clan	2	67
93	Clan Leaders	1	68
94	Miembros del clan	2	68
95	Clan Leaders	1	69
96	Miembros del clan	2	69
97	Clan Leaders	1	70
98	Miembros del clan	2	70
99	Clan Leaders	1	71
100	Miembros del clan	2	71
101	Clan Leaders	1	74
102	Miembros del clan	2	74
103	Clan Leaders	1	76
104	Miembros del clan	2	76
105	Clan Leaders	1	78
106	Miembros del clan	2	78
107	Clan Leaders	1	79
108	Miembros del clan	2	79
109	Clan Leaders	1	80
110	Miembros del clan	2	80
111	Clan Leaders	1	81
112	Miembros del clan	2	81
113	Clan Leaders	1	85
114	Miembros del clan	2	85
115	Clan Leaders	1	87
116	Miembros del clan	2	87
117	Clan Leaders	1	88
118	Miembros del clan	2	88
119	Clan Leaders	1	89
120	Miembros del clan	2	89
121	Clan Leaders	1	90
122	Miembros del clan	2	90
123	Clan Leaders	1	93
124	Miembros del clan	2	93
125	Clan Leaders	1	94
126	Miembros del clan	2	94
127	Clan Leaders	1	95
128	Miembros del clan	2	95
129	Clan Leaders	1	96
130	Miembros del clan	2	96
131	Clan Leaders	1	98
132	Miembros del clan	2	98
133	Clan Leaders	1	102
134	Miembros del clan	2	102
135	Clan Leaders	1	103
136	Miembros del clan	2	103
137	Clan Leaders	1	105
138	Miembros del clan	2	105
139	Clan Leaders	1	106
140	Miembros del clan	2	106
141	Clan Leaders	1	107
142	Miembros del clan	2	107
143	Clan Leaders	1	108
144	Miembros del clan	2	108
145	Clan Leaders	1	109
146	Miembros del clan	2	109
147	Clan Leaders	1	110
148	Miembros del clan	2	110
149	Clan Leaders	1	111
150	Miembros del clan	2	111
151	Clan Leaders	1	112
152	Miembros del clan	2	112
153	Clan Leaders	1	114
154	Miembros del clan	2	114
155	Clan Leaders	1	115
156	Miembros del clan	2	115
157	Clan Leaders	1	122
158	Miembros del clan	2	122
159	Clan Leaders	1	123
160	Miembros del clan	2	123
161	Clan Leaders	1	124
162	Miembros del clan	2	124
163	Clan Leaders	1	129
164	Miembros del clan	2	129
165	Clan Leaders	1	130
166	Miembros del clan	2	130
167	Clan Leaders	1	132
168	Miembros del clan	2	132
169	Clan Leaders	1	134
170	Miembros del clan	2	134
453	Clan Leaders	1	369
454	Miembros del clan	2	369
173	Clan Leaders	1	136
174	Miembros del clan	2	136
175	Clan Leaders	1	137
176	Miembros del clan	2	137
177	Clan Leaders	1	139
178	Miembros del clan	2	139
179	Clan Leaders	1	140
180	Miembros del clan	2	140
461	Clan Leaders	1	375
462	Miembros del clan	2	375
183	Clan Leaders	1	155
184	Miembros del clan	2	155
185	Clan Leaders	1	158
186	Miembros del clan	2	158
187	Clan Leaders	1	159
188	Miembros del clan	2	159
189	Clan Leaders	1	160
190	Miembros del clan	2	160
191	Clan Leaders	1	161
192	Miembros del clan	2	161
193	Clan Leaders	1	162
194	Miembros del clan	2	162
195	Clan Leaders	1	163
196	Miembros del clan	2	163
197	Clan Leaders	1	164
198	Miembros del clan	2	164
199	Clan Leaders	1	167
200	Miembros del clan	2	167
201	Clan Leaders	1	170
202	Miembros del clan	2	170
203	Clan Leaders	1	171
204	Miembros del clan	2	171
205	Clan Leaders	1	172
206	Miembros del clan	2	172
207	Clan Leaders	1	173
208	Miembros del clan	2	173
209	Clan Leaders	1	178
210	Miembros del clan	2	178
211	Clan Leaders	1	187
212	Miembros del clan	2	187
213	Clan Leaders	1	188
214	Miembros del clan	2	188
215	Clan Leaders	1	189
216	Miembros del clan	2	189
217	Clan Leaders	1	190
218	Miembros del clan	2	190
219	Clan Leaders	1	191
220	Miembros del clan	2	191
221	Clan Leaders	1	192
222	Miembros del clan	2	192
223	Clan Leaders	1	193
224	Miembros del clan	2	193
225	Clan Leaders	1	194
226	Miembros del clan	2	194
227	Clan Leaders	1	195
228	Miembros del clan	2	195
229	Clan Leaders	1	197
230	Miembros del clan	2	197
231	Clan Leaders	1	198
232	Miembros del clan	2	198
233	Clan Leaders	1	199
234	Miembros del clan	2	199
235	Clan Leaders	1	202
236	Miembros del clan	2	202
237	Clan Leaders	1	206
238	Miembros del clan	2	206
239	Clan Leaders	1	207
240	Miembros del clan	2	207
241	Clan Leaders	1	208
242	Miembros del clan	2	208
243	Clan Leaders	1	221
244	Miembros del clan	2	221
245	Clan Leaders	1	222
246	Miembros del clan	2	222
247	Clan Leaders	1	223
248	Miembros del clan	2	223
249	Clan Leaders	1	224
250	Miembros del clan	2	224
251	Clan Leaders	1	226
252	Miembros del clan	2	226
253	Clan Leaders	1	227
254	Miembros del clan	2	227
255	Clan Leaders	1	231
256	Miembros del clan	2	231
257	Clan Leaders	1	232
258	Miembros del clan	2	232
259	Clan Leaders	1	233
260	Miembros del clan	2	233
261	Clan Leaders	1	234
262	Miembros del clan	2	234
263	Clan Leaders	1	235
264	Miembros del clan	2	235
265	Clan Leaders	1	236
266	Miembros del clan	2	236
267	Clan Leaders	1	237
268	Miembros del clan	2	237
269	Clan Leaders	1	238
270	Miembros del clan	2	238
271	Clan Leaders	1	239
272	Miembros del clan	2	239
273	Clan Leaders	1	240
274	Miembros del clan	2	240
541	Clan Leaders	1	436
542	Miembros del clan	2	436
455	Clan Leaders	1	370
456	Miembros del clan	2	370
279	Clan Leaders	1	243
280	Miembros del clan	2	243
281	Clan Leaders	1	244
282	Miembros del clan	2	244
283	Clan Leaders	1	245
284	Miembros del clan	2	245
285	Clan Leaders	1	247
286	Miembros del clan	2	247
287	Clan Leaders	1	251
288	Miembros del clan	2	251
289	Clan Leaders	1	252
290	Miembros del clan	2	252
291	Clan Leaders	1	253
292	Miembros del clan	2	253
293	Clan Leaders	1	258
294	Miembros del clan	2	258
295	Clan Leaders	1	259
296	Miembros del clan	2	259
297	Clan Leaders	1	260
298	Miembros del clan	2	260
299	Clan Leaders	1	262
300	Miembros del clan	2	262
301	Clan Leaders	1	263
302	Miembros del clan	2	263
303	Clan Leaders	1	264
304	Miembros del clan	2	264
305	Clan Leaders	1	266
306	Miembros del clan	2	266
307	Clan Leaders	1	267
308	Miembros del clan	2	267
309	Clan Leaders	1	268
310	Miembros del clan	2	268
311	Clan Leaders	1	269
312	Miembros del clan	2	269
313	Clan Leaders	1	270
314	Miembros del clan	2	270
315	Clan Leaders	1	271
316	Miembros del clan	2	271
317	Clan Leaders	1	272
318	Miembros del clan	2	272
319	Clan Leaders	1	273
320	Miembros del clan	2	273
589	Clan Leaders	1	477
590	Miembros del clan	2	477
597	Clan Leaders	1	483
598	Miembros del clan	2	483
325	Clan Leaders	1	277
326	Miembros del clan	2	277
327	Clan Leaders	1	278
328	Miembros del clan	2	278
329	Clan Leaders	1	279
330	Miembros del clan	2	279
467	Clan Leaders	1	380
468	Miembros del clan	2	380
333	Clan Leaders	1	282
334	Miembros del clan	2	282
335	Clan Leaders	1	283
336	Miembros del clan	2	283
337	Clan Leaders	1	284
338	Miembros del clan	2	284
339	Clan Leaders	1	285
340	Miembros del clan	2	285
473	Clan Leaders	1	385
474	Miembros del clan	2	385
477	Clan Leaders	1	387
478	Miembros del clan	2	387
345	Clan Leaders	1	291
346	Miembros del clan	2	291
347	Clan Leaders	1	293
348	Miembros del clan	2	293
349	Clan Leaders	1	294
350	Miembros del clan	2	294
351	Clan Leaders	1	295
352	Miembros del clan	2	295
353	Clan Leaders	1	296
354	Miembros del clan	2	296
481	Clan Leaders	1	392
482	Miembros del clan	2	392
357	Clan Leaders	1	298
358	Miembros del clan	2	298
359	Clan Leaders	1	299
360	Miembros del clan	2	299
361	Clan Leaders	1	301
362	Miembros del clan	2	301
363	Clan Leaders	1	302
364	Miembros del clan	2	302
365	Clan Leaders	1	304
366	Miembros del clan	2	304
367	Clan Leaders	1	305
368	Miembros del clan	2	305
369	Clan Leaders	1	310
370	Miembros del clan	2	310
457	Clan Leaders	1	372
458	Miembros del clan	2	372
373	Clan Leaders	1	313
374	Miembros del clan	2	313
375	Clan Leaders	1	314
376	Miembros del clan	2	314
377	Clan Leaders	1	315
378	Miembros del clan	2	315
379	Clan Leaders	1	316
380	Miembros del clan	2	316
381	Clan Leaders	1	317
382	Miembros del clan	2	317
383	Clan Leaders	1	318
384	Miembros del clan	2	318
385	Clan Leaders	1	320
386	Miembros del clan	2	320
387	Clan Leaders	1	321
388	Miembros del clan	2	321
389	Clan Leaders	1	322
390	Miembros del clan	2	322
391	Clan Leaders	1	328
392	Miembros del clan	2	328
393	Clan Leaders	1	329
394	Miembros del clan	2	329
395	Clan Leaders	1	330
396	Miembros del clan	2	330
397	Clan Leaders	1	331
398	Miembros del clan	2	331
399	Clan Leaders	1	332
400	Miembros del clan	2	332
401	Clan Leaders	1	333
402	Miembros del clan	2	333
403	Clan Leaders	1	334
404	Miembros del clan	2	334
405	Clan Leaders	1	335
406	Miembros del clan	2	335
407	Clan Leaders	1	336
408	Miembros del clan	2	336
409	Clan Leaders	1	338
410	Miembros del clan	2	338
411	Clan Leaders	1	341
412	Miembros del clan	2	341
413	Clan Leaders	1	342
414	Miembros del clan	2	342
415	Clan Leaders	1	343
416	Miembros del clan	2	343
417	Clan Leaders	1	344
418	Miembros del clan	2	344
419	Clan Leaders	1	345
420	Miembros del clan	2	345
421	Clan Leaders	1	346
422	Miembros del clan	2	346
543	Clan Leaders	1	437
544	Miembros del clan	2	437
425	Clan Leaders	1	351
426	Miembros del clan	2	351
427	Clan Leaders	1	353
428	Miembros del clan	2	353
429	Clan Leaders	1	354
430	Miembros del clan	2	354
431	Clan Leaders	1	355
432	Miembros del clan	2	355
433	Clan Leaders	1	356
434	Miembros del clan	2	356
435	Clan Leaders	1	357
436	Miembros del clan	2	357
437	Clan Leaders	1	358
438	Miembros del clan	2	358
439	Clan Leaders	1	361
440	Miembros del clan	2	361
441	Clan Leaders	1	363
442	Miembros del clan	2	363
443	Clan Leaders	1	364
444	Miembros del clan	2	364
445	Clan Leaders	1	365
446	Miembros del clan	2	365
447	Clan Leaders	1	366
448	Miembros del clan	2	366
449	Clan Leaders	1	367
450	Miembros del clan	2	367
451	Clan Leaders	1	368
452	Miembros del clan	2	368
463	Clan Leaders	1	376
464	Miembros del clan	2	376
469	Clan Leaders	1	381
470	Miembros del clan	2	381
475	Clan Leaders	1	386
476	Miembros del clan	2	386
479	Clan Leaders	1	388
480	Miembros del clan	2	388
483	Clan Leaders	1	394
484	Miembros del clan	2	394
485	Clan Leaders	1	395
486	Miembros del clan	2	395
487	Clan Leaders	1	396
488	Miembros del clan	2	396
583	Clan Leaders	1	471
584	Miembros del clan	2	471
591	Clan Leaders	1	478
592	Miembros del clan	2	478
493	Clan Leaders	1	402
494	Miembros del clan	2	402
495	Clan Leaders	1	403
496	Miembros del clan	2	403
497	Clan Leaders	1	404
498	Miembros del clan	2	404
499	Clan Leaders	1	405
500	Miembros del clan	2	405
501	Clan Leaders	1	406
502	Miembros del clan	2	406
503	Clan Leaders	1	408
504	Miembros del clan	2	408
505	Clan Leaders	1	409
506	Miembros del clan	2	409
507	Clan Leaders	1	410
508	Miembros del clan	2	410
509	Clan Leaders	1	411
510	Miembros del clan	2	411
511	Clan Leaders	1	412
512	Miembros del clan	2	412
513	Clan Leaders	1	413
514	Miembros del clan	2	413
515	Clan Leaders	1	414
516	Miembros del clan	2	414
585	Clan Leaders	1	474
586	Miembros del clan	2	474
519	Clan Leaders	1	416
520	Miembros del clan	2	416
521	Clan Leaders	1	417
522	Miembros del clan	2	417
523	Clan Leaders	1	419
524	Miembros del clan	2	419
525	Clan Leaders	1	421
526	Miembros del clan	2	421
527	Clan Leaders	1	422
528	Miembros del clan	2	422
529	Clan Leaders	1	427
530	Miembros del clan	2	427
531	Clan Leaders	1	428
532	Miembros del clan	2	428
533	Clan Leaders	1	429
534	Miembros del clan	2	429
535	Clan Leaders	1	430
536	Miembros del clan	2	430
537	Clan Leaders	1	434
538	Miembros del clan	2	434
593	Clan Leaders	1	479
594	Miembros del clan	2	479
545	Clan Leaders	1	440
546	Miembros del clan	2	440
599	Clan Leaders	1	484
600	Miembros del clan	2	484
601	Clan Leaders	1	486
602	Miembros del clan	2	486
559	Clan Leaders	1	448
560	Miembros del clan	2	448
603	Clan Leaders	1	490
604	Miembros del clan	2	490
605	Clan Leaders	1	491
606	Miembros del clan	2	491
607	Clan Leaders	1	494
608	Miembros del clan	2	494
569	Clan Leaders	1	454
570	Miembros del clan	2	454
571	Clan Leaders	1	455
572	Miembros del clan	2	455
609	Clan Leaders	1	496
610	Miembros del clan	2	496
575	Clan Leaders	1	458
576	Miembros del clan	2	458
577	Clan Leaders	1	459
578	Miembros del clan	2	459
581	Clan Leaders	1	470
582	Miembros del clan	2	470
611	Clan Leaders	1	497
612	Miembros del clan	2	497
613	Clan Leaders	1	507
614	Miembros del clan	2	507
615	Clan Leaders	1	508
616	Miembros del clan	2	508
617	Clan Leaders	1	510
618	Miembros del clan	2	510
619	Clan Leaders	1	511
620	Miembros del clan	2	511
621	Clan Leaders	1	514
622	Miembros del clan	2	514
623	Clan Leaders	1	518
624	Miembros del clan	2	518
625	Clan Leaders	1	520
626	Miembros del clan	2	520
627	Clan Leaders	1	521
628	Miembros del clan	2	521
629	Clan Leaders	1	522
630	Miembros del clan	2	522
631	Clan Leaders	1	523
632	Miembros del clan	2	523
633	Clan Leaders	1	525
634	Miembros del clan	2	525
635	Clan Leaders	1	526
636	Miembros del clan	2	526
637	Clan Leaders	1	531
638	Miembros del clan	2	531
639	Clan Leaders	1	533
640	Miembros del clan	2	533
641	Clan Leaders	1	534
642	Miembros del clan	2	534
645	Clan Leaders	1	536
646	Miembros del clan	2	536
647	Clan Leaders	1	538
648	Miembros del clan	2	538
649	Clan Leaders	1	539
650	Miembros del clan	2	539
651	Clan Leaders	1	540
652	Miembros del clan	2	540
653	Clan Leaders	1	541
654	Miembros del clan	2	541
655	Clan Leaders	1	542
656	Miembros del clan	2	542
657	Clan Leaders	1	544
658	Miembros del clan	2	544
659	Clan Leaders	1	545
660	Miembros del clan	2	545
661	Clan Leaders	1	547
662	Miembros del clan	2	547
663	Clan Leaders	1	549
664	Miembros del clan	2	549
665	Clan Leaders	1	550
666	Miembros del clan	2	550
667	Clan Leaders	1	551
668	Miembros del clan	2	551
669	Clan Leaders	1	552
670	Miembros del clan	2	552
671	Clan Leaders	1	553
672	Miembros del clan	2	553
673	Clan Leaders	1	554
674	Miembros del clan	2	554
675	Clan Leaders	1	555
676	Miembros del clan	2	555
677	Clan Leaders	1	556
678	Miembros del clan	2	556
679	Clan Leaders	1	557
680	Miembros del clan	2	557
681	Clan Leaders	1	559
682	Miembros del clan	2	559
683	Clan Leaders	1	560
684	Miembros del clan	2	560
685	Clan Leaders	1	575
686	Miembros del clan	2	575
687	Clan Leaders	1	576
688	Miembros del clan	2	576
689	Clan Leaders	1	577
690	Miembros del clan	2	577
691	Clan Leaders	1	578
692	Miembros del clan	2	578
693	Clan Leaders	1	579
694	Miembros del clan	2	579
695	Clan Leaders	1	580
696	Miembros del clan	2	580
697	Clan Leaders	1	583
698	Miembros del clan	2	583
699	Clan Leaders	1	585
700	Miembros del clan	2	585
701	Clan Leaders	1	586
702	Miembros del clan	2	586
703	Clan Leaders	1	587
704	Miembros del clan	2	587
705	Clan Leaders	1	588
706	Miembros del clan	2	588
707	Clan Leaders	1	589
708	Miembros del clan	2	589
709	Clan Leaders	1	591
710	Miembros del clan	2	591
711	Clan Leaders	1	592
712	Miembros del clan	2	592
713	Clan Leaders	1	593
714	Miembros del clan	2	593
715	Clan Leaders	1	594
716	Miembros del clan	2	594
717	Clan Leaders	1	596
718	Miembros del clan	2	596
719	Clan Leaders	1	599
720	Miembros del clan	2	599
721	Clan Leaders	1	600
722	Miembros del clan	2	600
723	Clan Leaders	1	601
724	Miembros del clan	2	601
725	Clan Leaders	1	602
726	Miembros del clan	2	602
727	Clan Leaders	1	603
728	Miembros del clan	2	603
729	Clan Leaders	1	604
730	Miembros del clan	2	604
731	Clan Leaders	1	605
732	Miembros del clan	2	605
733	Clan Leaders	1	606
734	Miembros del clan	2	606
735	Clan Leaders	1	607
736	Miembros del clan	2	607
737	Clan Leaders	1	608
738	Miembros del clan	2	608
739	Clan Leaders	1	613
740	Miembros del clan	2	613
741	Clan Leaders	1	614
742	Miembros del clan	2	614
743	Clan Leaders	1	615
744	Miembros del clan	2	615
745	Clan Leaders	1	616
746	Miembros del clan	2	616
747	Clan Leaders	1	617
748	Miembros del clan	2	617
749	Clan Leaders	1	618
750	Miembros del clan	2	618
751	Clan Leaders	1	619
752	Miembros del clan	2	619
753	Clan Leaders	1	620
754	Miembros del clan	2	620
755	Clan Leaders	1	621
756	Miembros del clan	2	621
757	Clan Leaders	1	622
758	Miembros del clan	2	622
759	Clan Leaders	1	623
760	Miembros del clan	2	623
761	Clan Leaders	1	624
762	Miembros del clan	2	624
763	Clan Leaders	1	625
764	Miembros del clan	2	625
765	Clan Leaders	1	630
766	Miembros del clan	2	630
767	Clan Leaders	1	631
768	Miembros del clan	2	631
769	Clan Leaders	1	632
770	Miembros del clan	2	632
771	Clan Leaders	1	633
772	Miembros del clan	2	633
773	Clan Leaders	1	634
774	Miembros del clan	2	634
775	Clan Leaders	1	635
776	Miembros del clan	2	635
827	Clan Leaders	1	663
828	Miembros del clan	2	663
779	Clan Leaders	1	638
780	Miembros del clan	2	638
781	Clan Leaders	1	639
782	Miembros del clan	2	639
783	Clan Leaders	1	640
784	Miembros del clan	2	640
785	Clan Leaders	1	641
786	Miembros del clan	2	641
787	Clan Leaders	1	642
788	Miembros del clan	2	642
789	Clan Leaders	1	643
790	Miembros del clan	2	643
791	Clan Leaders	1	644
792	Miembros del clan	2	644
793	Clan Leaders	1	645
794	Miembros del clan	2	645
795	Clan Leaders	1	646
796	Miembros del clan	2	646
797	Clan Leaders	1	647
798	Miembros del clan	2	647
799	Clan Leaders	1	648
800	Miembros del clan	2	648
801	Clan Leaders	1	649
802	Miembros del clan	2	649
803	Clan Leaders	1	650
804	Miembros del clan	2	650
805	Clan Leaders	1	652
806	Miembros del clan	2	652
807	Clan Leaders	1	653
808	Miembros del clan	2	653
809	Clan Leaders	1	654
810	Miembros del clan	2	654
811	Clan Leaders	1	655
812	Miembros del clan	2	655
813	Clan Leaders	1	656
814	Miembros del clan	2	656
815	Clan Leaders	1	657
816	Miembros del clan	2	657
817	Clan Leaders	1	658
818	Miembros del clan	2	658
819	Clan Leaders	1	659
820	Miembros del clan	2	659
821	Clan Leaders	1	660
822	Miembros del clan	2	660
823	Clan Leaders	1	661
824	Miembros del clan	2	661
825	Clan Leaders	1	662
826	Miembros del clan	2	662
829	Clan Leaders	1	666
830	Miembros del clan	2	666
831	Clan Leaders	1	667
832	Miembros del clan	2	667
833	Clan Leaders	1	670
834	Miembros del clan	2	670
835	Clan Leaders	1	671
836	Miembros del clan	2	671
837	Clan Leaders	1	672
838	Miembros del clan	2	672
839	Clan Leaders	1	680
840	Miembros del clan	2	680
841	Clan Leaders	1	681
842	Miembros del clan	2	681
843	Clan Leaders	1	683
844	Miembros del clan	2	683
845	Clan Leaders	1	685
846	Miembros del clan	2	685
847	Clan Leaders	1	689
848	Miembros del clan	2	689
849	Clan Leaders	1	691
850	Miembros del clan	2	691
851	Clan Leaders	1	693
852	Miembros del clan	2	693
853	Clan Leaders	1	694
854	Miembros del clan	2	694
855	Clan Leaders	1	696
856	Miembros del clan	2	696
857	Clan Leaders	1	697
858	Miembros del clan	2	697
859	Clan Leaders	1	699
860	Miembros del clan	2	699
861	Clan Leaders	1	700
862	Miembros del clan	2	700
863	Clan Leaders	1	702
864	Miembros del clan	2	702
865	Clan Leaders	1	703
866	Miembros del clan	2	703
867	Clan Leaders	1	704
868	Miembros del clan	2	704
869	Clan Leaders	1	706
870	Miembros del clan	2	706
871	Clan Leaders	1	707
872	Miembros del clan	2	707
873	Clan Leaders	1	708
874	Miembros del clan	2	708
875	Clan Leaders	1	711
876	Miembros del clan	2	711
877	Clan Leaders	1	713
878	Miembros del clan	2	713
879	Clan Leaders	1	714
880	Miembros del clan	2	714
881	Clan Leaders	1	715
882	Miembros del clan	2	715
883	Clan Leaders	1	716
884	Miembros del clan	2	716
885	Clan Leaders	1	717
886	Miembros del clan	2	717
887	Clan Leaders	1	718
888	Miembros del clan	2	718
889	Clan Leaders	1	719
890	Miembros del clan	2	719
891	Clan Leaders	1	720
892	Miembros del clan	2	720
893	Clan Leaders	1	721
894	Miembros del clan	2	721
895	Clan Leaders	1	722
896	Miembros del clan	2	722
897	Clan Leaders	1	724
898	Miembros del clan	2	724
899	Clan Leaders	1	725
900	Miembros del clan	2	725
901	Clan Leaders	1	726
902	Miembros del clan	2	726
903	Clan Leaders	1	727
904	Miembros del clan	2	727
905	Clan Leaders	1	728
906	Miembros del clan	2	728
907	Clan Leaders	1	731
908	Miembros del clan	2	731
909	Clan Leaders	1	732
910	Miembros del clan	2	732
911	Clan Leaders	1	733
912	Miembros del clan	2	733
913	Clan Leaders	1	734
914	Miembros del clan	2	734
915	Clan Leaders	1	736
916	Miembros del clan	2	736
917	Clan Leaders	1	737
918	Miembros del clan	2	737
919	Clan Leaders	1	738
920	Miembros del clan	2	738
921	Clan Leaders	1	741
922	Miembros del clan	2	741
923	Clan Leaders	1	742
924	Miembros del clan	2	742
925	Clan Leaders	1	743
926	Miembros del clan	2	743
927	Clan Leaders	1	744
928	Miembros del clan	2	744
929	Clan Leaders	1	745
930	Miembros del clan	2	745
931	Clan Leaders	1	746
932	Miembros del clan	2	746
933	Clan Leaders	1	747
934	Miembros del clan	2	747
935	Clan Leaders	1	750
936	Miembros del clan	2	750
1009	Clan Leaders	1	806
1010	Miembros del clan	2	806
1011	Clan Leaders	1	808
1012	Miembros del clan	2	808
1013	Clan Leaders	1	809
1014	Miembros del clan	2	809
1015	Clan Leaders	1	812
1016	Miembros del clan	2	812
1017	Clan Leaders	1	813
1018	Miembros del clan	2	813
1019	Clan Leaders	1	814
1020	Miembros del clan	2	814
949	Clan Leaders	1	760
950	Miembros del clan	2	760
951	Clan Leaders	1	761
952	Miembros del clan	2	761
953	Clan Leaders	1	762
954	Miembros del clan	2	762
955	Clan Leaders	1	763
956	Miembros del clan	2	763
957	Clan Leaders	1	764
958	Miembros del clan	2	764
959	Clan Leaders	1	766
960	Miembros del clan	2	766
961	Clan Leaders	1	767
962	Miembros del clan	2	767
963	Clan Leaders	1	768
964	Miembros del clan	2	768
965	Clan Leaders	1	769
966	Miembros del clan	2	769
967	Clan Leaders	1	771
968	Miembros del clan	2	771
969	Clan Leaders	1	773
970	Miembros del clan	2	773
971	Clan Leaders	1	774
972	Miembros del clan	2	774
973	Clan Leaders	1	775
974	Miembros del clan	2	775
975	Clan Leaders	1	777
976	Miembros del clan	2	777
977	Clan Leaders	1	778
978	Miembros del clan	2	778
979	Clan Leaders	1	780
980	Miembros del clan	2	780
981	Clan Leaders	1	784
982	Miembros del clan	2	784
983	Clan Leaders	1	785
984	Miembros del clan	2	785
985	Clan Leaders	1	786
986	Miembros del clan	2	786
987	Clan Leaders	1	788
988	Miembros del clan	2	788
989	Clan Leaders	1	791
990	Miembros del clan	2	791
991	Clan Leaders	1	792
992	Miembros del clan	2	792
993	Clan Leaders	1	793
994	Miembros del clan	2	793
995	Clan Leaders	1	794
996	Miembros del clan	2	794
997	Clan Leaders	1	797
998	Miembros del clan	2	797
999	Clan Leaders	1	800
1000	Miembros del clan	2	800
1001	Clan Leaders	1	801
1002	Miembros del clan	2	801
1003	Clan Leaders	1	803
1004	Miembros del clan	2	803
1005	Clan Leaders	1	804
1006	Miembros del clan	2	804
1007	Clan Leaders	1	805
1008	Miembros del clan	2	805
1021	Clan Leaders	1	815
1022	Miembros del clan	2	815
1023	Clan Leaders	1	816
1024	Miembros del clan	2	816
1025	Clan Leaders	1	817
1026	Miembros del clan	2	817
1027	Clan Leaders	1	818
1028	Miembros del clan	2	818
1029	Clan Leaders	1	820
1030	Miembros del clan	2	820
1031	Clan Leaders	1	821
1032	Miembros del clan	2	821
1033	Clan Leaders	1	822
1034	Miembros del clan	2	822
1035	Clan Leaders	1	823
1036	Miembros del clan	2	823
1037	Clan Leaders	1	824
1038	Miembros del clan	2	824
1039	Clan Leaders	1	829
1040	Miembros del clan	2	829
1041	Clan Leaders	1	830
1042	Miembros del clan	2	830
1043	Clan Leaders	1	831
1044	Miembros del clan	2	831
1045	Clan Leaders	1	837
1046	Miembros del clan	2	837
1047	Clan Leaders	1	839
1048	Miembros del clan	2	839
1049	Clan Leaders	1	840
1050	Miembros del clan	2	840
1051	Clan Leaders	1	841
1052	Miembros del clan	2	841
1053	Clan Leaders	1	846
1054	Miembros del clan	2	846
1055	Clan Leaders	1	849
1056	Miembros del clan	2	849
1057	Clan Leaders	1	850
1058	Miembros del clan	2	850
1059	Clan Leaders	1	851
1060	Miembros del clan	2	851
1061	Clan Leaders	1	852
1062	Miembros del clan	2	852
1063	Clan Leaders	1	853
1064	Miembros del clan	2	853
1065	Clan Leaders	1	854
1066	Miembros del clan	2	854
1067	Clan Leaders	1	855
1068	Miembros del clan	2	855
1069	Clan Leaders	1	857
1070	Miembros del clan	2	857
1071	Clan Leaders	1	858
1072	Miembros del clan	2	858
1073	Clan Leaders	1	859
1074	Miembros del clan	2	859
1075	Clan Leaders	1	860
1076	Miembros del clan	2	860
1077	Clan Leaders	1	861
1078	Miembros del clan	2	861
1079	Clan Leaders	1	862
1080	Miembros del clan	2	862
1081	Clan Leaders	1	863
1082	Miembros del clan	2	863
1083	Clan Leaders	1	865
1084	Miembros del clan	2	865
1085	Clan Leaders	1	866
1086	Miembros del clan	2	866
1087	Clan Leaders	1	867
1088	Miembros del clan	2	867
1089	Clan Leaders	1	868
1090	Miembros del clan	2	868
1091	Clan Leaders	1	869
1092	Miembros del clan	2	869
1093	Clan Leaders	1	874
1094	Miembros del clan	2	874
1095	Clan Leaders	1	876
1096	Miembros del clan	2	876
1097	Clan Leaders	1	877
1098	Miembros del clan	2	877
1099	Clan Leaders	1	881
1100	Miembros del clan	2	881
1101	Clan Leaders	1	885
1102	Miembros del clan	2	885
1103	Clan Leaders	1	886
1104	Miembros del clan	2	886
1105	Clan Leaders	1	888
1106	Miembros del clan	2	888
1107	Clan Leaders	1	892
1108	Miembros del clan	2	892
1109	Clan Leaders	1	893
1110	Miembros del clan	2	893
1111	Clan Leaders	1	895
1112	Miembros del clan	2	895
1113	Clan Leaders	1	896
1114	Miembros del clan	2	896
1115	Clan Leaders	1	898
1116	Miembros del clan	2	898
1117	Clan Leaders	1	900
1118	Miembros del clan	2	900
1119	Clan Leaders	1	901
1120	Miembros del clan	2	901
1121	Clan Leaders	1	906
1122	Miembros del clan	2	906
1123	Clan Leaders	1	907
1124	Miembros del clan	2	907
1125	Clan Leaders	1	908
1126	Miembros del clan	2	908
1127	Clan Leaders	1	911
1128	Miembros del clan	2	911
1129	Clan Leaders	1	914
1130	Miembros del clan	2	914
1131	Clan Leaders	1	916
1132	Miembros del clan	2	916
1133	Clan Leaders	1	917
1134	Miembros del clan	2	917
1135	Clan Leaders	1	918
1136	Miembros del clan	2	918
1137	Clan Leaders	1	919
1138	Miembros del clan	2	919
1139	Clan Leaders	1	920
1140	Miembros del clan	2	920
1141	Clan Leaders	1	921
1142	Miembros del clan	2	921
1143	Clan Leaders	1	922
1144	Miembros del clan	2	922
1145	Clan Leaders	1	926
1146	Miembros del clan	2	926
1147	Clan Leaders	1	927
1148	Miembros del clan	2	927
1149	Clan Leaders	1	928
1150	Miembros del clan	2	928
1151	Clan Leaders	1	929
1152	Miembros del clan	2	929
1153	Clan Leaders	1	930
1154	Miembros del clan	2	930
1155	Clan Leaders	1	932
1156	Miembros del clan	2	932
1157	Clan Leaders	1	933
1158	Miembros del clan	2	933
1159	Clan Leaders	1	934
1160	Miembros del clan	2	934
1161	Clan Leaders	1	936
1162	Miembros del clan	2	936
1163	Clan Leaders	1	939
1164	Miembros del clan	2	939
1165	Clan Leaders	1	941
1166	Miembros del clan	2	941
1167	Clan Leaders	1	942
1168	Miembros del clan	2	942
1169	Clan Leaders	1	944
1170	Miembros del clan	2	944
1171	Clan Leaders	1	945
1172	Miembros del clan	2	945
1173	Clan Leaders	1	946
1174	Miembros del clan	2	946
1175	Clan Leaders	1	948
1176	Miembros del clan	2	948
1177	Clan Leaders	1	951
1178	Miembros del clan	2	951
1179	Clan Leaders	1	956
1180	Miembros del clan	2	956
1181	Clan Leaders	1	957
1182	Miembros del clan	2	957
1183	Clan Leaders	1	958
1184	Miembros del clan	2	958
1185	Clan Leaders	1	959
1186	Miembros del clan	2	959
1187	Clan Leaders	1	960
1188	Miembros del clan	2	960
1189	Clan Leaders	1	965
1190	Miembros del clan	2	965
1191	Clan Leaders	1	967
1192	Miembros del clan	2	967
1193	Clan Leaders	1	968
1194	Miembros del clan	2	968
1195	Clan Leaders	1	969
1196	Miembros del clan	2	969
1197	Clan Leaders	1	970
1198	Miembros del clan	2	970
1199	Clan Leaders	1	973
1200	Miembros del clan	2	973
1201	Clan Leaders	1	974
1202	Miembros del clan	2	974
1203	Clan Leaders	1	975
1204	Miembros del clan	2	975
1205	Clan Leaders	1	976
1206	Miembros del clan	2	976
1207	Clan Leaders	1	979
1208	Miembros del clan	2	979
1209	Clan Leaders	1	980
1210	Miembros del clan	2	980
1211	Clan Leaders	1	981
1212	Miembros del clan	2	981
1213	Clan Leaders	1	982
1214	Miembros del clan	2	982
1215	Clan Leaders	1	983
1216	Miembros del clan	2	983
1217	Clan Leaders	1	985
1218	Miembros del clan	2	985
1219	Clan Leaders	1	986
1220	Miembros del clan	2	986
1221	Clan Leaders	1	988
1222	Miembros del clan	2	988
1223	Clan Leaders	1	991
1224	Miembros del clan	2	991
1225	Clan Leaders	1	992
1226	Miembros del clan	2	992
1227	Clan Leaders	1	993
1228	Miembros del clan	2	993
1229	Clan Leaders	1	994
1230	Miembros del clan	2	994
1231	Clan Leaders	1	997
1232	Miembros del clan	2	997
1233	Clan Leaders	1	998
1234	Miembros del clan	2	998
1235	Clan Leaders	1	1000
1236	Miembros del clan	2	1000
1237	Clan Leaders	1	1001
1238	Miembros del clan	2	1001
1239	Clan Leaders	1	1002
1240	Miembros del clan	2	1002
1241	Clan Leaders	1	1003
1242	Miembros del clan	2	1003
1243	Clan Leaders	1	1004
1244	Miembros del clan	2	1004
1245	Clan Leaders	1	1005
1246	Miembros del clan	2	1005
1247	Clan Leaders	1	1006
1248	Miembros del clan	2	1006
1249	Clan Leaders	1	1009
1250	Miembros del clan	2	1009
1251	Clan Leaders	1	1010
1252	Miembros del clan	2	1010
1253	Clan Leaders	1	1011
1254	Miembros del clan	2	1011
1255	Clan Leaders	1	1012
1256	Miembros del clan	2	1012
1257	Clan Leaders	1	1017
1258	Miembros del clan	2	1017
1259	Clan Leaders	1	1019
1260	Miembros del clan	2	1019
1261	Clan Leaders	1	1021
1262	Miembros del clan	2	1021
1263	Clan Leaders	1	1022
1264	Miembros del clan	2	1022
1265	Clan Leaders	1	1026
1266	Miembros del clan	2	1026
1267	Clan Leaders	1	1028
1268	Miembros del clan	2	1028
1269	Clan Leaders	1	1029
1270	Miembros del clan	2	1029
1271	Clan Leaders	1	1030
1272	Miembros del clan	2	1030
1273	Clan Leaders	1	1031
1274	Miembros del clan	2	1031
1275	Clan Leaders	1	1032
1276	Miembros del clan	2	1032
1277	Clan Leaders	1	1035
1278	Miembros del clan	2	1035
1279	Clan Leaders	1	1036
1280	Miembros del clan	2	1036
1281	Clan Leaders	1	1037
1282	Miembros del clan	2	1037
1283	Clan Leaders	1	1039
1284	Miembros del clan	2	1039
1285	Clan Leaders	1	1040
1286	Miembros del clan	2	1040
1287	Clan Leaders	1	1042
1288	Miembros del clan	2	1042
1289	Clan Leaders	1	1043
1290	Miembros del clan	2	1043
1291	Clan Leaders	1	1044
1292	Miembros del clan	2	1044
1293	Clan Leaders	1	1053
1294	Miembros del clan	2	1053
1295	Clan Leaders	1	1054
1296	Miembros del clan	2	1054
1297	Clan Leaders	1	1055
1298	Miembros del clan	2	1055
1299	Clan Leaders	1	1058
1300	Miembros del clan	2	1058
1301	Clan Leaders	1	1059
1302	Miembros del clan	2	1059
1303	Clan Leaders	1	1060
1304	Miembros del clan	2	1060
1305	Clan Leaders	1	1061
1306	Miembros del clan	2	1061
1307	Clan Leaders	1	1063
1308	Miembros del clan	2	1063
1309	Clan Leaders	1	1064
1310	Miembros del clan	2	1064
1311	Clan Leaders	1	1065
1312	Miembros del clan	2	1065
1313	Clan Leaders	1	1066
1314	Miembros del clan	2	1066
1315	Clan Leaders	1	1069
1316	Miembros del clan	2	1069
1317	Clan Leaders	1	1070
1318	Miembros del clan	2	1070
1319	Clan Leaders	1	1071
1320	Miembros del clan	2	1071
1321	Clan Leaders	1	1073
1322	Miembros del clan	2	1073
1323	Clan Leaders	1	1075
1324	Miembros del clan	2	1075
1325	Clan Leaders	1	1076
1326	Miembros del clan	2	1076
1327	Clan Leaders	1	1081
1328	Miembros del clan	2	1081
1329	Clan Leaders	1	1082
1330	Miembros del clan	2	1082
1331	Clan Leaders	1	1084
1332	Miembros del clan	2	1084
1333	Clan Leaders	1	1085
1334	Miembros del clan	2	1085
1335	Clan Leaders	1	1086
1336	Miembros del clan	2	1086
1337	Clan Leaders	1	1087
1338	Miembros del clan	2	1087
1339	Clan Leaders	1	1088
1340	Miembros del clan	2	1088
1341	Clan Leaders	1	1089
1342	Miembros del clan	2	1089
1343	Clan Leaders	1	1090
1344	Miembros del clan	2	1090
1345	Clan Leaders	1	1091
1346	Miembros del clan	2	1091
1347	Clan Leaders	1	1092
1348	Miembros del clan	2	1092
1349	Clan Leaders	1	1093
1350	Miembros del clan	2	1093
1351	Clan Leaders	1	1094
1352	Miembros del clan	2	1094
1353	Clan Leaders	1	1096
1354	Miembros del clan	2	1096
1355	Clan Leaders	1	1097
1356	Miembros del clan	2	1097
1357	Clan Leaders	1	1098
1358	Miembros del clan	2	1098
1359	Clan Leaders	1	1099
1360	Miembros del clan	2	1099
1361	Clan Leaders	1	1100
1362	Miembros del clan	2	1100
1363	Clan Leaders	1	1101
1364	Miembros del clan	2	1101
1365	Clan Leaders	1	1102
1366	Miembros del clan	2	1102
1367	Clan Leaders	1	1108
1368	Miembros del clan	2	1108
1369	Clan Leaders	1	1109
1370	Miembros del clan	2	1109
1371	Clan Leaders	1	1114
1372	Miembros del clan	2	1114
1373	Clan Leaders	1	1115
1374	Miembros del clan	2	1115
1375	Clan Leaders	1	1116
1376	Miembros del clan	2	1116
1377	Clan Leaders	1	1117
1378	Miembros del clan	2	1117
1379	Clan Leaders	1	1118
1380	Miembros del clan	2	1118
1381	Clan Leaders	1	1120
1382	Miembros del clan	2	1120
1383	Clan Leaders	1	1121
1384	Miembros del clan	2	1121
\.


--
-- Name: clans_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_pkey PRIMARY KEY (id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT "$1" FOREIGN KEY (type_id) REFERENCES clans_groups_types(id) MATCH FULL;


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT "$2" FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- PostgreSQL database dump complete
--

