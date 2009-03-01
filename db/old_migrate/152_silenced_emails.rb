class SilencedEmails < ActiveRecord::Migration
  def self.up
    slonik_execute "
CREATE TABLE public.silenced_emails
(
  id serial primary key not null unique,
  email character varying NOT NULL,
  CONSTRAINT silenced_emails_email_key UNIQUE (email)
)
WITH (OIDS=FALSE);

CREATE INDEX silenced_emails_lower
  ON public.silenced_emails
  USING btree
  (lower(email::text));

    "
  end

  def self.down
  end
end
