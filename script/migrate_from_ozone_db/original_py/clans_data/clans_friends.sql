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
-- Name: clans_friends; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE clans_friends (
    from_clan_id integer NOT NULL,
    from_wants boolean DEFAULT false NOT NULL,
    to_clan_id integer NOT NULL,
    to_wants boolean DEFAULT false NOT NULL
);


--
-- Data for Name: clans_friends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clans_friends (from_clan_id, from_wants, to_clan_id, to_wants) FROM stdin;
137	t	19	t
94	t	3	f
471	f	282	f
87	t	26	f
17	t	136	t
696	t	21	t
368	f	21	f
301	t	19	t
301	t	137	f
78	t	26	f
199	t	202	f
522	t	368	t
301	t	14	f
619	t	78	f
187	f	21	f
549	t	87	f
3	t	13	t
533	t	531	t
199	t	301	f
26	t	3	t
93	t	14	t
322	t	188	f
19	t	14	t
90	t	87	t
29	f	260	f
305	t	71	f
549	t	535	f
106	t	78	t
78	t	13	t
87	t	13	f
722	t	696	f
139	t	3	f
139	t	21	f
134	f	3	f
238	t	137	f
17	t	139	f
199	t	260	f
172	t	17	f
346	t	95	f
470	t	21	f
471	f	356	f
137	t	14	f
137	t	17	f
422	f	89	f
93	t	19	t
137	f	188	f
137	f	93	f
305	t	23	t
87	t	3	t
408	t	21	f
137	t	81	f
90	t	3	t
238	t	14	t
187	f	3	f
187	f	55	f
726	t	576	f
55	f	13	f
55	f	3	f
366	t	367	t
322	t	81	f
29	f	234	f
330	t	3	f
191	t	17	f
23	t	21	t
322	f	137	t
295	t	202	f
385	t	19	f
385	t	238	f
385	t	93	f
381	t	369	t
538	t	525	f
295	f	294	f
536	f	136	f
43	t	3	f
346	t	21	f
191	t	13	f
700	t	368	f
346	t	159	f
29	f	202	f
395	t	21	f
301	f	112	f
29	f	193	f
5	t	17	f
508	f	369	f
614	f	576	f
29	f	236	f
484	t	29	t
136	t	381	f
136	t	613	f
518	t	369	t
507	t	17	f
522	t	21	f
301	f	81	f
522	f	112	f
136	t	592	f
295	t	484	t
199	t	295	t
295	f	193	f
614	f	368	f
536	t	369	t
459	f	278	f
320	t	95	f
459	f	134	f
536	t	381	t
518	t	381	t
658	t	671	t
320	t	159	f
542	t	545	t
545	t	21	f
592	t	381	f
320	f	330	f
346	f	330	f
29	f	301	f
295	t	29	t
592	t	536	t
170	t	17	f
170	t	411	f
576	t	541	t
550	f	541	t
541	t	368	f
541	t	189	f
541	t	591	f
641	t	655	f
449	f	301	f
449	f	525	f
449	f	295	t
320	t	21	t
617	t	550	f
617	t	55	f
617	t	222	f
617	t	545	f
617	t	278	f
55	f	21	f
641	t	661	t
21	f	95	f
641	t	646	f
614	f	591	f
542	f	21	f
658	t	549	f
278	f	134	f
550	f	134	f
559	t	305	f
632	f	364	f
632	f	21	f
632	f	3	f
714	t	358	f
632	f	163	f
660	t	632	t
696	f	552	f
721	t	696	f
726	t	614	f
726	t	681	f
614	t	806	f
714	t	295	f
714	t	525	f
801	t	808	f
714	t	449	f
714	f	344	f
304	f	134	t
304	t	21	f
812	f	689	f
685	t	812	t
484	f	449	f
804	t	632	t
645	t	653	f
801	t	641	f
804	t	660	f
804	t	736	f
29	f	525	f
160	t	29	f
699	f	840	f
841	t	699	t
846	t	801	f
846	t	3	f
846	t	21	f
778	t	536	t
518	t	536	f
422	t	536	t
800	t	792	f
855	t	3	f
855	t	21	f
855	t	525	f
849	f	5	f
859	t	549	f
865	t	699	f
868	f	44	f
865	t	736	f
21	t	736	f
736	f	632	t
865	t	841	t
650	f	614	f
885	t	301	f
892	t	614	f
892	t	21	f
892	t	726	f
892	t	550	f
892	f	576	f
892	t	681	f
911	t	305	f
911	t	23	f
911	t	71	f
893	t	526	f
893	t	525	f
893	t	301	f
893	t	551	f
893	f	29	f
893	t	295	f
930	t	635	f
928	f	726	f
928	f	541	f
928	t	21	f
928	t	576	f
928	t	681	f
928	t	580	f
614	f	550	f
614	f	55	f
614	f	696	t
614	f	328	f
928	t	614	t
951	t	240	t
960	t	106	f
960	t	21	f
933	f	541	f
981	f	808	f
981	t	641	f
981	f	646	f
933	f	888	f
933	t	970	f
988	t	928	f
988	t	614	f
988	t	726	f
988	t	580	f
988	t	576	f
936	t	951	t
936	t	932	f
1000	t	991	t
80	f	74	f
80	f	356	f
1006	f	659	f
1012	t	550	f
1012	f	780	f
1019	t	80	f
992	t	29	t
538	t	29	f
455	t	29	f
199	t	29	t
29	t	449	f
1053	t	958	f
794	t	699	f
559	t	23	f
559	t	1000	t
800	t	936	t
1065	t	3	f
1065	t	381	f
1069	t	381	f
1069	t	17	f
1069	t	536	f
1069	t	518	f
936	t	240	t
240	f	658	f
321	t	301	f
321	t	188	f
321	t	112	f
321	t	19	f
1116	t	1064	f
1116	t	1069	f
1100	t	865	f
1100	t	841	f
1100	t	699	f
1100	t	736	f
1121	t	240	f
1121	t	936	f
321	t	14	t
136	t	369	t
775	t	632	t
775	t	804	f
775	t	21	f
792	t	951	f
240	f	792	t
1069	t	369	f
1065	t	369	f
550	f	278	t
550	f	888	t
797	t	369	f
994	f	576	f
623	t	369	f
\.


--
-- Name: clans_friends_from_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_from_clan_id_fkey FOREIGN KEY (from_clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_friends_to_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_to_clan_id_fkey FOREIGN KEY (to_clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

