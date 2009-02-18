class Gm2081 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column sent_emails int;"
    slonik_execute "create index sent_emails_created_on on sent_emails(created_on);"
    execute "update stats.general set sent_emails = (select count(*) FROM sent_emails where date_trunc('day', created_on)::date = stats.general.created_on) where created_on >= (select created_on from sent_emails order by id asc limit 1);"
  end

  def self.down
  end
end
