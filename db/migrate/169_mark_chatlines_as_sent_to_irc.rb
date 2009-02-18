class MarkChatlinesAsSentToIrc < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table chatlines add column sent_to_irc bool not null default 'f';"
  end

  def self.down
  end
end
