class Gm2051 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table comments add column deleted bool not null default 'f';"
  end

  def self.down
  end
end
