class DelayedJobsIntegration < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE public.delayed_jobs
(
  id serial,
  priority integer DEFAULT 0,
  attempts integer DEFAULT 0,
  \"handler\" text,
  last_error character varying(255),
  run_at timestamp without time zone,
  locked_at timestamp without time zone,
  failed_at timestamp without time zone,
  locked_by character varying(255),
  created_at timestamp without time zone,
  updated_at timestamp without time zone,
  CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id)
) 
WITHOUT OIDS;"
    
    execute "alter table global_vars alter column svn_revision type varchar;"
  end
  
  def self.down
  end
end
