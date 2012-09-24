class KarmaPaid < ActiveRecord::Migration
  def up
    execute "alter table contents add column karma_paid bool not null default 'f';"
    execute "alter table comments add column karma_paid bool not null default 'f';"
  end

  def down
  end
end
