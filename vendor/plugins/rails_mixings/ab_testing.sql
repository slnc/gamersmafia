CREATE SEQUENCE public.goals_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.goals_id_seq OWNER TO postgres;

CREATE SEQUENCE public.ab_tests_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 18
  CACHE 1;
ALTER TABLE public.ab_tests_id_seq OWNER TO postgres;

CREATE TABLE public.ab_tests
(
  id integer NOT NULL DEFAULT nextval('ab_tests_id_seq'::regclass),
  name character varying NOT NULL,
  treatments integer NOT NULL,
  finished boolean NOT NULL DEFAULT false,
  minimum_difference numeric(10,2),
  metrics character varying,
  info_url character varying,
  created_on timestamp without time zone NOT NULL DEFAULT now(),
  completed_on timestamp without time zone,
  min_difference numeric(10,2) NOT NULL DEFAULT 0.05,
  cache_conversion_rates character varying,
  updated_on timestamp without time zone NOT NULL DEFAULT now(),
  dirty boolean NOT NULL DEFAULT true,
  cache_expected_completion_date timestamp without time zone,
  CONSTRAINT ab_tests_pkey PRIMARY KEY (id),
  CONSTRAINT ab_tests_name_key UNIQUE (name)
)
WITH (OIDS=FALSE);
ALTER TABLE public.ab_tests OWNER TO postgres;

-- Table: public.treated_visitors

-- DROP TABLE public.treated_visitors;

CREATE TABLE public.treated_visitors
(
  id integer NOT NULL DEFAULT nextval('treated_visitors_id_seq'::regclass),
  ab_test_id integer NOT NULL,
  visitor_id character varying NOT NULL,
  treatment integer NOT NULL,
  CONSTRAINT treated_visitors_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE public.treated_visitors OWNER TO postgres;

CREATE SEQUENCE public.treated_visitors_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 162243
  CACHE 1;
ALTER TABLE public.treated_visitors_id_seq OWNER TO postgres;


CREATE UNIQUE INDEX treated_visitors_per_test
  ON public.treated_visitors
  USING btree
  (ab_test_id, visitor_id);

