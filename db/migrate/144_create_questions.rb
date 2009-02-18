class CreateQuestions < ActiveRecord::Migration
  def self.up
    slonik_execute "CREATE TABLE public.questions
(
  id SERIAL PRIMARY KEY,
  title character varying NOT NULL,
  questions_category_id integer NOT NULL,
  description text NOT NULL,
  created_on timestamp without time zone NOT NULL DEFAULT now(),
  updated_on timestamp without time zone NOT NULL DEFAULT now(),
  user_id integer NOT NULL,
  accepted_answer_comment_id int references comments,
  hits_anonymous integer NOT NULL DEFAULT 0,
  hits_registered integer NOT NULL DEFAULT 0,
  cache_rating smallint,
  cache_rated_times smallint,
  cache_comments_count integer NOT NULL DEFAULT 0,
  log character varying,
  state smallint NOT NULL DEFAULT 0,
  cache_weighted_rank numeric(10,2),
  CONSTRAINT questions_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES public.users (id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE public.questions OWNER TO postgres;

CREATE INDEX questions_state
  ON public.questions
  USING btree
  (state);

CREATE INDEX questions_user_id
  ON public.questions
  USING btree
  (user_id);"
    
    
    slonik_execute "CREATE TABLE public.questions_categories
(
  id SERIAL PRIMARY KEY,
  name character varying NOT NULL,
  forum_category_id integer,
  questions_count integer NOT NULL DEFAULT 0,
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
  nohome boolean NOT NULL DEFAULT false,
  CONSTRAINT questions_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id)
      REFERENCES public.questions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT questions_categories_parent_id_fkey FOREIGN KEY (parent_id)
      REFERENCES public.questions_categories (id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT questions_categories_toplevel_id_fkey FOREIGN KEY (root_id)
      REFERENCES public.questions_categories (id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT questions_categories_clan_id_fkey FOREIGN KEY (clan_id)
      REFERENCES public.clans (id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE public.questions_categories OWNER TO postgres;

-- Index: public.questions_categories_code_name_parent_id

-- DROP INDEX public.questions_categories_code_name_parent_id;

CREATE UNIQUE INDEX questions_categories_code_name_parent_id
  ON public.questions_categories
  USING btree
  (code, name, parent_id);"
    
    slonik_execute "alter table questions add foreign key(questions_category_id) references questions_categories MATCH FULL;"
  end

  def self.down
    
  end
end
